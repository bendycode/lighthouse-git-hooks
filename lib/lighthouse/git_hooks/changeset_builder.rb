require 'fileutils'
require 'date'
module Lighthouse::GitHooks

  class ChangesetBuilder < Base
    def initialize(old_rev, new_rev, ref=nil)
      super()

      Dir.chdir Configuration[:repository_path] do
        @commits = `git log --name-status --pretty=format:"|%H|%cn|%ci|%s" #{old_rev}..#{new_rev}`
        # hash, committer name, commit date, message
      end

      current_commit = nil
      @commits.each_line do |l|
        unless l =~ /^|/
          current_commit.changes << l
          next
        end
        current_commit.save if current_commit
        data = l.split('|', 4)
        current_commit = Lighthouse::Changeset.new(:project_id => Configuration[:project_id].to_i)
        current_commit.body = l[3]
        current_commit.title = "#{l[2]} committed changeset #{l[0]}"
        current_commit.revision = l[0]
        current_commit.changed_at = l[2]
        current_commit.changes = []
      end
      current_commit.save
    rescue Exception => e
      $stderr.puts "Failed to save changeset #{current_commit.inspect} because:"
      $stderr.puts e.inspect
      $stderr.puts e.backtrace.join("\n")
    end

  end
end

