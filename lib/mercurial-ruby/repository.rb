module Mercurial  
  class RepositoryNotFound < Error; end
  
  class Repository
    
    def self.create(destination)
      init_repository(destination)      
    end
    
    def self.open(destination)
      if File.exists?(destination)
        new(destination)
      else
        raise Mercurial::RepositoryNotFound.new(destination)
      end
    end

    def self.clone(url, destination, cmd_options)
      create_destination(destination)
      opts = cmd_options.merge(:append_hg => true)
      Mercurial::Shell.run(["clone ? ?", url, destination], opts)
      open(destination)      
    end
    
    def initialize(source)
      @path = source
    end
    
    def shell
      @_shell ||= Mercurial::Shell.new(self)
    end
    
    def config
      @_config ||= Mercurial::ConfigFile.new(self)
    end
    
    def hooks
      @_hook_factory ||= Mercurial::HookFactory.new(self)
    end
    
    def commits
      @_commits ||= Mercurial::CommitFactory.new(self)
    end
    
    def branches
      @_branches ||= Mercurial::BranchFactory.new(self)
    end
    
    def tags
      @_tags ||= Mercurial::TagFactory.new(self)
    end
    
    def diffs
      @_diffs ||= Mercurial::DiffFactory.new(self)
    end
    
    def nodes
      @_nodes ||= Mercurial::NodeFactory.new(self)
    end
    
    def blames
      @_blames ||= Mercurial::BlameFactory.new(self)
    end
    
    def manifest
      @_manifest ||= Mercurial::Manifest.new(self)
    end
    
    def file_index
      @_file_index ||= Mercurial::FileIndex.new(self)
    end
    
    def node(name, hash_id)
      nodes.find(name, hash_id)
    end
    
    def clone(destination_path, cmd_options={})
      self.class.clone(file_system_url, destination_path, cmd_options)
    end
    
    def pull(origin='default', cmd_options={})
      shell.hg(['pull ?', origin], cmd_options)
    end
    
    def verify
      shell.hg('verify')
      true
    rescue Mercurial::CommandError
      false
    end
    
    def paths
      {}.tap do |result|
        shell.hg('paths').each do |line|
          path, url = *line.strip.split(" = ")
          result[path] = url
        end
      end
    end
    
    def destroy!
      FileUtils.rm_rf(path)
    end
    
    def file_system_url
      %Q[file://#{ path }]
    end
    
    def path
      File.expand_path(@path)
    end
    
    def dothg_path
      File.join(path, '.hg')
    end
    
    def mtime
      File.mtime(dothg_path).to_i
    end
    
    def no_cache
      @cache_disabled_by_override = true
      yield
      @cache_disabled_by_override = false
    end
    
    def cache_disabled_by_override?
      @cache_disabled_by_override || false
    end
    
  protected

    def self.create_destination(path)
      Mercurial::Shell.run("mkdir -p #{ path }")
    end
  
    def self.init_repository(destination)
      create_destination(destination)
      open(destination).tap do |repo|
        repo.shell.hg('init', :cache => false)
        repo.shell.hg('update null', :cache => false)
      end
    end
    
  end
  
end
