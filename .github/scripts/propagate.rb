#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "open3"
require "tempfile"

class Propagator
  EXCLUDED_FILES = %w[
    .github/workflows/propagate-downstream.yml
    .github/scripts/propagate.rb
    .github/downstream_repos.json
  ].freeze

  # Index stages git records for an unmerged path. Cherry-picking makes the
  # downstream checkout "ours" and the template commit "theirs".
  DOWNSTREAM_STAGE = 2
  TEMPLATE_STAGE = 3

  def initialize
    @gh_token           = ENV.fetch("GH_TOKEN")
    @merge_sha          = ENV.fetch("MERGE_SHA")
    @template_repo      = ENV.fetch("TEMPLATE_REPO")
    @downstream_repo    = ENV.fetch("DOWNSTREAM_REPO")
    @pr_title           = ENV.fetch("PR_TITLE")
    @pr_number          = ENV.fetch("PR_NUMBER")
    @pr_url             = ENV.fetch("PR_URL")
    @branch             = "template-update/#{@pr_number}"
    @has_conflicts      = false
    @claude_resolved    = false
    @conflicted_files   = []
    @deleted_files      = []
  end

  def prepare
    clone_downstream
    Dir.chdir("downstream") do
      if branch_exists?
        set_output("skip", "true")
        return
      end

      configure_git
      fetch_template
      run!("git", "checkout", "-b", @branch)
      cherry_pick

      set_output("has_conflicts", @has_conflicts.to_s)
      set_output("conflicted_files", @conflicted_files.join("\n"))
      set_output("deleted_files", @deleted_files.join("\n"))
    end
  end

  def finalize
    Dir.chdir("downstream") do
      @has_conflicts = ENV["HAS_CONFLICTS"] == "true"
      @conflicted_files = ENV.fetch("CONFLICTED_FILES", "").split("\n").reject(&:empty?)
      @deleted_files = ENV.fetch("DELETED_FILES", "").split("\n").reject(&:empty?)

      if @has_conflicts && @conflicted_files.any?
        has_conflict_markers = @conflicted_files.any? do |file|
          File.exist?(file) && File.read(file).include?("<<<<<<<")
        end
        @claude_resolved = !has_conflict_markers
      end

      restore_excluded_files
      run!("git", "add", "-A")
      return if no_changes?

      FileUtils.rm_f(".git/CHERRY_PICK_HEAD")
      commit
      run!("git", "push", "origin", @branch)
      open_pr
    end
  end

  private

  def clone_downstream
    run!("git", "clone",
      "https://x-access-token:#{@gh_token}@github.com/#{@downstream_repo}.git",
      "downstream")
  end

  def branch_exists?
    stdout, = Open3.capture2("git", "ls-remote", "--heads", "origin", @branch)
    if stdout.include?(@branch)
      puts "Branch #{@branch} already exists on #{@downstream_repo}, skipping"
      true
    else
      false
    end
  end

  def configure_git
    run!("git", "config", "user.name", "Template Bot")
    run!("git", "config", "user.email", "template-bot@users.noreply.github.com")
  end

  def fetch_template
    run!("git", "remote", "add", "template", "https://github.com/#{@template_repo}.git")
    run!("git", "fetch", "template", "main", "--depth=5")
  end

  def cherry_pick
    stdout, = Open3.capture2("git", "cat-file", "-p", @merge_sha)
    parent_count = stdout.lines.count { |l| l.start_with?("parent") }

    args = ["-x", "--no-commit"]
    args = ["-m", "1", *args] if parent_count > 1

    return if system("git", "cherry-pick", *args, @merge_sha)

    # Excluded files don't exist downstream, so any template change touching
    # them conflicts by construction. Clear those before escalating to Claude.
    restore_excluded_files

    conflicts, deletions = unmerged_paths.partition do |_, stages|
      stages.include?(DOWNSTREAM_STAGE) && stages.include?(TEMPLATE_STAGE)
    end

    apply_deletions(deletions.map(&:first))

    @conflicted_files = conflicts.map(&:first)
    @has_conflicts = @conflicted_files.any?
  end

  # Unmerged index entries, mapped to the stages git recorded for each path.
  # A path missing a stage is one that side deleted.
  def unmerged_paths
    stdout, = Open3.capture2("git", "ls-files", "-u")
    stages = Hash.new { |paths, path| paths[path] = [] }

    stdout.lines.each do |line|
      metadata, path = line.split("\t", 2)
      stages[path.strip] << Integer(metadata.split.last, 10)
    end

    stages
  end

  # A file deleted on one side and modified on the other leaves no conflict
  # markers, so Claude can neither see the conflict nor resolve it: it has no
  # tool that deletes files. Honour the deletion instead, since whichever side
  # removed the file meant to remove it.
  def apply_deletions(files)
    @deleted_files = files
    files.each { |file| run!("git", "rm", "-f", "-q", file) }
  end

  def restore_excluded_files
    EXCLUDED_FILES.each do |file|
      unless system("git", "checkout", "HEAD", "--", file, out: File::NULL, err: File::NULL)
        system("git", "rm", "-f", file, out: File::NULL, err: File::NULL)
      end
    end
  end

  def no_changes?
    if system("git", "diff", "--cached", "--quiet")
      puts "No applicable changes for #{@downstream_repo}, skipping"
      true
    else
      false
    end
  end

  def commit
    parts = [@pr_title, commit_body, "Source: #{@pr_url}"].reject(&:empty?)
    run!("git", "commit", "-m", parts.join("\n\n"))
  end

  def commit_body
    @commit_body ||=
      Open3.capture2("git", "log", "-1", "--format=%b", @merge_sha).first.strip
  end

  def open_pr
    Tempfile.create("pr-body") do |f|
      f.write(pr_body)
      f.flush
      run!("gh", "pr", "create",
        "--repo", @downstream_repo,
        "--title", @pr_title,
        "--body-file", f.path,
        "--assignee", "mockdeep")
    end
  end

  def pr_body
    lines = ["## Template Update", ""]
    lines += [commit_body, ""] unless commit_body.empty?
    lines << "Cherry-picked from #{@pr_url}"
    lines += deleted_files_note if @deleted_files.any?

    if @claude_resolved
      lines += [
        "",
        "> [!WARNING]",
        "> **Conflicts were automatically resolved by Claude.** Please review these files carefully:",
        "",
        *@conflicted_files.map { |file| "- `#{file}`" }
      ]
    elsif @has_conflicts
      lines += [
        "",
        "> [!WARNING]",
        "> **This PR has conflicts that need manual resolution.** Search for `<<<<<<<` in the changed files."
      ]
    end

    lines.join("\n")
  end

  def deleted_files_note
    [
      "",
      "> [!NOTE]",
      "> **Deleted despite local changes.** Each of these was removed on one side and modified on the other, so the deletion was kept. Restore any you still need:",
      "",
      *@deleted_files.map { |file| "- `#{file}`" }
    ]
  end

  def set_output(name, value)
    output_file = ENV["GITHUB_OUTPUT"]
    return unless output_file

    File.open(output_file, "a") do |f|
      if value.include?("\n")
        f.puts "#{name}<<EOF"
        f.puts value
        f.puts "EOF"
      else
        f.puts "#{name}=#{value}"
      end
    end
  end

  def run!(*cmd)
    system(*cmd) or raise "Command failed: #{cmd.join(" ")}"
  end
end

case ARGV[0]
when "prepare"
  Propagator.new.prepare
when "finalize"
  Propagator.new.finalize
else
  raise "Usage: propagate.rb [prepare|finalize]"
end
