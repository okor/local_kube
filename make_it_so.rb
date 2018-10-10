WORK_DIR = Dir.pwd + '/clusters'

def collect
  valid_charts = { extended_charts: [], proper_charts: [] }
  Dir.chdir(WORK_DIR)
  charts = Dir.glob("*/*/*").reject { |d| d.count('/') < 2 }
  charts.each do |cluster_chart|
    context, namespace, release_name = cluster_chart.split('/')
    chart_file_path = "#{cluster_chart}/CHART"
    if File.file?(chart_file_path)
      valid_charts[:extended_charts].push({
        remote_chart: remote_chart = File.read(chart_file_path).chomp,
        context: context,
        namespace: namespace,
        release_name: release_name
      })
    else
      # "TODO: Support proper charts"
    end
  end
  valid_charts
end

def helm_install(chart, dry_run, config_file=nil)
  command = [
    "helm",
    "upgrade --install #{chart[:release_name]} #{chart[:remote_chart]}",
    "#{'--dry-run' if dry_run}",
    "--kube-context #{chart[:context]}",
    "--namespace #{chart[:namespace]}",
    "#{'-f ' + config_file if config_file}"
  ].reject(&:empty?).join(' ')
  puts "Executing#{' (dryrun)' if dry_run}: #{command}"
  `#{command}`
end

def kubectl_apply(chart, dry_run, config_file)
  command = "kubectl --context #{chart[:context]} apply #{'--dry-run' if dry_run} -f #{config_file}"
  puts "Executing#{' (dryrun)' if dry_run}: #{command}"
  `#{command}`
end

def install_all(charts:, dry_run: true)
  charts[:extended_charts].each do |chart|
    if chart[:remote_chart]
      config_files = Dir.glob("#{WORK_DIR}/#{chart[:context]}/#{chart[:namespace]}/#{chart[:release_name]}/**.yaml")
      config_files.each do |config_file|
        if config_file =~ /values\.yaml/
          helm_install(chart, dry_run, config_file)
        else
          kubectl_apply(chart, dry_run, config_file)
        end
      end
      helm_install(chart, dry_run) if config_files.count < 1
    end
  end
end

def delete_all(charts:, dry_run: true)
  charts[:extended_charts].each do |chart|
    command = [
      "helm",
      "delete --purge",
      "#{'--dry-run' if dry_run}",
      "#{chart[:release_name]}"
    ].reject(&:empty?).join(' ')
    puts "Executing: #{command}"
    `#{command}`
  end
end

if ARGV&.length && ARGV.first == 'delete'
  begin
    delete_all(charts: collect)
  rescue Exception => e
    puts "Error (#{e})"
  else
    delete_all(charts: collect, dry_run: false)
  end
else
  begin
    install_all(charts: collect)
  rescue Exception => e
    puts "Error (#{e})"
  else
    install_all(charts: collect, dry_run: false)
  end
end
