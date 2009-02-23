require 'fileutils'
require 'date'
module Lighthouse::GitHooks

  class ChangesetBuilder < Base
    def initialize(old_rev, new_rev, ref=nil)
      super()


      Dir.chdir Configuration[:repository_path] do
        @commits = `git log --name-status --pretty=format:"|%H|%cn|%ce|%ci|%s" #{old_rev}..#{new_rev}`
        # hash, committer name, commit date, message
      end

      current_commit = nil
      current_user = nil
      @commits.each_line do |l|
        unless l =~ /^|/
          current_commit.changes << l
          next
        end
        if current_commit
          Configuration.login(current_user)
          current_commit.save
        end
        data = l.split('|', 6)
        current_commit = Lighthouse::Changeset.new(:project_id => Configuration[:project_id].to_i)
        current_commit.body = data[5]
        current_commit.title = "#{data[2]} committed changeset #{data[1]}"
        current_commit.revision = data[1]
        current_commit.changed_at = DateTime.parse(data[4])
        current_commit.changes = []
        current_user = data[3]
      end
      current_commit.save
    rescue Exception => e
      $stderr.puts "Failed to save changeset #{current_commit.inspect} because:"
      $stderr.puts e.inspect
      $stderr.puts e.backtrace.join("\n")
    end

  end
end

