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
    end
  end

  def finalize
    Dir.chdir("downstream") do
      @has_conflicts = ENV["HAS_CONFLICTS"] == "true"
      @conflicted_files = ENV.fetch("CONFLICTED_FILES", "").split("\n").reject(&:empty?)

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

    @has_conflicts = true
    stdout, = Open3.capture2("git", "diff", "--name-only", "--diff-filter=U")
    @conflicted_files = stdout.strip.split("\n")
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
    message = "Apply template update: #{@pr_title}\n\nSource: #{@pr_url}"
    run!("git", "commit", "-m", message)
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
    lines = ["## Template Update", "", "Cherry-picked from #{@pr_url}"]

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
