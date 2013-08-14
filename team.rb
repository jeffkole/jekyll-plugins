module Jekyll
  class TeamIndex < Page
    def initialize(site, base, dir)
      @site = site
      @base = base
      @dir  = dir
      @name = "index.html"

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'team.html')
      self.data['team'] = self.get_team(site)
    end

    def get_team(site)
      {}.tap do |team|
        Dir['_team/*.yml'].each do |path|
          name   = File.basename(path, '.yml')
          config = YAML.load(File.read(File.join(@base, path)))
          type   = config['type']

          if config['active']
            team[type] = {} if team[type].nil?
            team[type][name] = config
          end
        end
      end
    end
  end

  class PersonIndex < Page
    def initialize(site, base, dir, path)
      @site     = site
      @base     = base
      @dir      = dir
      @name     = "index.html"

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'profile.html')
      self.data = self.data.merge(YAML.load(File.read(File.join(@base, path))))
      self.data['title'] = "#{self.data['name']} | #{self.data['role']}"
    end
  end

  class GenerateTeam < Generator
    safe true
    priority :normal

    def generate(site)
      write_team(site)
    end

    # Loops through the list of team pages and processes each one.
    def write_team(site)
      if Dir.exists?('_team')
        Dir.chdir('_team')
        Dir["*.yml"].each do |path|
          name = File.basename(path, '.yml')
          self.write_person_index(site, "_team/#{path}", name)
        end

        Dir.chdir(site.source)
        self.write_team_index(site)
      end
    end

    def write_team_index(site)
      team = TeamIndex.new(site, site.source, "/team")
      site.pages << team
    end

    def write_person_index(site, path, name)
      person = PersonIndex.new(site, site.source, "/team/#{name}", path)
      site.pages << person
    end
  end

  class AuthorsTag < Liquid::Tag

    def initialize(tag_name, text, tokens)
      super
      @text   = text
      @tokens = tokens
    end

    def render(context)
      site = context.environments.first["site"]
      page = context.environments.first["page"]

      authors = context.scopes.last['author']
      authors = page['author'] if page && page['author']
      authors = [authors] if authors.is_a?(String)

      if authors
        "".tap do |output|
          authors.each do |author|
            slug = "#{author.downcase.gsub(/[ .]/, '-')}"
            file = File.join(site['source'], '_team', "#{slug}.yml")
            if File.exists?(file)
              data              = YAML.load(File.read(file))
              data['permalink'] = "/team/#{slug}"
              template          = File.read(File.join(site['source'], '_includes', 'author.html'))

              output << Liquid::Template.parse(template).render('author' => data)
            else
              output << author
            end
          end
        end
      end
    end
  end
end

Liquid::Template.register_tag('authors', Jekyll::AuthorsTag)
