require File.dirname(__FILE__) + '/../../vendor/lighthouse-api/lib/lighthouse'
require File.dirname(__FILE__) + '/../../vendor/grit/lib/grit'
module Lighthouse::GitHooks

  class Base

    def initialize
      @repo = Grit::Repo.new(Configuration[:repository_path])
    end

  end # Base
end

Dir[File.dirname(__FILE__) + '/git_hooks/*.rb'].each do |file|
  require file
end
