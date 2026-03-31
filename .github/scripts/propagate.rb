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
    @claude_oauth_token = ENV["CLAUDE_CODE_OAUTH_TOKEN"]
    @merge_sha          = ENV.fetch("MERGE_SHA")
    @template_repo      = ENV.fetch("TEMPLATE_REPO")
    @downstream_repo    = ENV.fetch("DOWNSTREAM_REPO")
    @pr_title           = ENV.fetch("PR_TITLE")
    @pr_number          = ENV.fetch("PR_NUMBER")
    @pr_url             = ENV.fetch("PR_URL")
    @github_actor       = ENV.fetch("GITHUB_ACTOR")
    @branch             = "template-update/#{@pr_number}"
    @has_conflicts      = false
    @claude_resolved    = false
    @conflicted_files   = []
  end

  def run
    clone_downstream
    Dir.chdir("downstream") do
      return if branch_exists?

      configure_git
      fetch_template
      run!("git", "checkout", "-b", @branch)
      cherry_pick
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

    if @claude_oauth_token && @conflicted_files.any?
      resolve_with_claude
    else
      run!("git", "add", "-A")
    end
  end

  def resolve_with_claude
    puts "Attempting to resolve conflicts with Claude Code..."
    run!("npm", "install", "-g", "@anthropic-ai/claude-code", "--silent")

    prompt = <<~PROMPT
      You are resolving merge conflicts in a downstream repository that tracks a template.

      Context:
      - Template repository: #{@template_repo}
      - Downstream repository: #{@downstream_repo}
      - Template change being applied: "#{@pr_title}" (#{@pr_url})

      Files with conflicts (containing <<<<<<< markers):
      #{@conflicted_files.join("\n")}

      Instructions:
      1. Read each conflicted file
      2. Resolve every conflict. Default strategy:
         - If the template adds something new (new lines, new config, new functionality), include it alongside the downstream changes
         - If the changes are incompatible, prefer downstream customizations unless the template change is a clear improvement (security fix, critical update)
      3. After resolving all files, run: git add -A
      4. Confirm no conflict markers remain: git diff --name-only --diff-filter=U
    PROMPT

    env = { "CLAUDE_CODE_OAUTH_TOKEN" => @claude_oauth_token }
    claude_succeeded = system(env, "claude", "-p", prompt, "--dangerously-skip-permissions")

    stdout, = Open3.capture2("git", "diff", "--name-only", "--diff-filter=U")
    if claude_succeeded && stdout.strip.empty?
      @claude_resolved = true
      run!("git", "add", "-A")
    else
      puts "Claude did not fully resolve conflicts, keeping conflict markers"
      run!("git", "add", "-A")
    end
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
        "--title", "Template: #{@pr_title}",
        "--body-file", f.path,
        "--assignee", @github_actor)
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
        *@conflicted_files.map { |f| "- `#{f}`" }
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

  def run!(*cmd)
    system(*cmd) or raise "Command failed: #{cmd.join(" ")}"
  end
end

Propagator.new.run
