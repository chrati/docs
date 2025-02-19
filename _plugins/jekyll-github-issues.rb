module Jekyll
  # Generates a GitHub issues data file
  class GithubIssuesGenerator < Jekyll::Generator
    DATA_FILE = '_data/github-issues.json'.freeze
    GITHUB_API_HOST = 'api.github.com'.freeze
    ISSUES_URL = '/search/issues?q=author:%s&per_page=100&page=%i'.freeze  # Geändert: Suche nach Issues

    def generate(site)
      settings = {
        'cache' => 300,
        'page_limit' => 10
      }.merge(site.config['githubissues'])

      Jekyll.logger.info "Checking if file needs to be regenerated..."

      # Überprüfen, ob die Datei existiert und das Cache-Intervall abgelaufen ist
      if File.exist?(DATA_FILE) && (File.mtime(DATA_FILE) + settings['cache']) > Time.now
        Jekyll.logger.info "Cache is still valid. Skipping regeneration."
        return
      end

      Jekyll.logger.info 'Generating Github issues data file'
      
      issues = []
      client = Net::HTTP.new(GITHUB_API_HOST, 443)
      client.use_ssl = true

      page = 1
      loop do
        url = format(ISSUES_URL, settings['username'], page)
        response = client.get(url, 'Accept' => 'application/json')
        
        # Debugging-Ausgabe der API-Antwort
        if response.code != '200'
          Jekyll.logger.warn "Could not retrieve GitHub data: #{response.body}"
          return
        else
          Jekyll.logger.info "GitHub API Response: #{response.body}"  # Gibt die Antwort aus
        end

        results = JSON.parse(response.body)
        issues.concat(results['items'])

        # Debugging-Ausgabe der Anzahl der abgerufenen Issues
        Jekyll.logger.info "Retrieved #{results['items'].size} issues from page #{page}"

        break if page >= settings['page_limit'].to_i
        break if issues.length >= results['total_count']
        page += 1
      end

      # Überprüfen, ob das Verzeichnis '_data' existiert
      Dir.mkdir('_data') unless Dir.exist?('_data')

      # Die Issues in die JSON-Datei schreiben
      Jekyll.logger.info "Writing issues data to #{DATA_FILE}"
      File.write(DATA_FILE, issues.to_json)
    end
  end
end
