require 'jekyll'
require 'net/http'
require 'json'

module Jekyll
  # Generates a GitHub issues data file
  class GithubIssuesGenerator < Jekyll::Generator
    DATA_FILE = '_data/github-issues.json'.freeze
    GITHUB_API_HOST = 'api.github.com'.freeze
    ISSUES_URL = '/search/issues?q=is:issue+is:open&per_page=100&page=%i'.freeze


    def generate(site)
      settings = {
        'cache' => 300,
        'page_limit' => 10
      }.merge(site.config['githubissues'])

      return if File.exist?(DATA_FILE) && (File.mtime(DATA_FILE) + settings['cache']) > Time.now
      Jekyll.logger.info 'Generating Github issues data file'

      issues = []

      client = Net::HTTP.new(GITHUB_API_HOST, 443)
      client.use_ssl = true

      page = 1
      loop do
        url = format(ISSUES_URL, settings['username'], page)
        response = client.get(url, 'Accept' => 'application/json')
        if response.code != '200'
          Jekyll.logger.warn "Could not retrieve GitHub data: #{response.body}"
          return
        end

        results = JSON.parse(response.body)
        issues.concat(results['items'])

        break if page >= settings['page_limit'].to_i
        break if issues.length >= results['total_count']
        page += 1
      end

      Dir.mkdir('_data') unless Dir.exist?('_data')
      File.write(DATA_FILE, issues.to_json)
    end
  end
end

