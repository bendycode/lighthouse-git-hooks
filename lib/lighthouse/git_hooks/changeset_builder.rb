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
        current_commit = Lighthouse::Changeset.new(:body=>l[3],
                                       :title=>"#{l[2]} committed changeset #{l[0]}",
                                       :revision=>l[0],
                                       :changed_at=>l[2],
                                       :project_id => Configuration[:project_id].to_i)
      end
      current_commit.save
    end

  end
end

