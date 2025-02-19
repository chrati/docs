require 'jekyll'
require 'net/http'
require 'json'

module Jekyll
  # Generates a GitHub issues data file
  class GithubIssuesGenerator < Jekyll::Generator
    DATA_FILE = '_data/github-issues.json'.freeze
    GITHUB_API_HOST = 'api.github.com'.freeze
    ISSUES_URL = '/search/issues?q=is:issue+is:open&per_page=100&page=%i'.freeze  # Entfernt den author-Filter

    def generate(site)
      settings = {
        'cache' => 300,  # Cache-Zeit in Sekunden
        'page_limit' => 10  # Maximale Anzahl von Seiten, die abgerufen werden
      }.merge(site.config['githubissues'])

      Jekyll.logger.info "Checking if file needs to be regenerated..."

      # Überprüfen, ob die Datei bereits existiert und das Cache-Intervall noch gültig ist
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
        url = format(ISSUES_URL, page)
        response = client.get(url, 'Accept' => 'application/json')

        # Ausgabe der API-Antwort für Debugging
        Jekyll.logger.info "GitHub API Response Code: #{response.code}"
        Jekyll.logger.info "GitHub API Response Body: #{response.body}"

        # Fehlerbehandlung für fehlgeschlagene API-Aufrufe
        if response.code != '200'
          Jekyll.logger.warn "Could not retrieve GitHub data: #{response.body}"
          return
        end

        # Verarbeiten der JSON-Antwort
        results = JSON.parse(response.body)

        # Ausgabe der abgerufenen Issues für Debugging
        Jekyll.logger.info "Retrieved #{results['items'].size} issues from page #{page}"

        issues.concat(results['items'])

        # Breche die Schleife ab, wenn das Limit erreicht ist oder alle Issues abgerufen wurden
        break if page >= settings['page_limit'].to_i
        break if issues.length >= results['total_count']
        page += 1
      end

      # Überprüfen, ob das Verzeichnis '_data' existiert
      Dir.mkdir('_data') unless Dir.exist?('_data')

      # Ausgabe der Daten in die JSON-Datei
      Jekyll.logger.info "Writing issues data to #{DATA_FILE}"
      File.write(DATA_FILE, issues.to_json)

      Jekyll.logger.info "Successfully generated the github-issues.json file."
    end
  end
end
