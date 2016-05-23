include_recipe 'apt'
include_recipe 'postgresql_lwrp::apt_official_repository'
include_recipe 'nginx::official-repo'

node.default['zabbix']['version'] = '3.0'
node.default['zabbix']['api-version'] = '2.4.7'

include_recipe 'zabbix_lwrp::default'
include_recipe 'zabbix_lwrp::partition'
include_recipe 'zabbix_lwrp::database'
include_recipe 'zabbix_lwrp::server'
include_recipe 'zabbix_lwrp::web'
include_recipe 'zabbix_lwrp::host'

zabbix_application 'Test application' do
  action :sync

  (0..5).each do |i|
    item "vfs.fs.size[/var/log#{i},free]" do
      type :active
      name "Free disk space on /var/log#{i}"
    end
  end

  trigger "Number #{node['fqdn']} of free inodes on log < 10%" do
    expression "{#{node['fqdn']}:vfs.fs.size[/var/log0,free].last(0)}>0"
    severity :high
  end
end

(0..5).each do |i|
  zabbix_graph "Graph #{i}" do
    action :create
    width 640
    height 480
    graph_items [key: "vfs.fs.size[/var/log#{i},free]", color: i.to_s * 6, y_axis_side: :left]
  end
end

zabbix_screen 'Test Screen' do
  action :sync
  hsize 1
  vsize 6
  (0..5).each do |i|
    screen_item "Graph #{i}" do
      resource_type :graph
      height 200
      width 900
      y i
    end
  end
end

zabbix_media_type 'sms' do
  action :create
  type :sms
  modem '/dev/modem'
end

zabbix_user_group 'Test group' do
  action :create
end

zabbix_action 'Test action' do
  event_source :triggers
  operation do
    user_groups 'Test group'
    message do
      use_default_message false
      subject 'Test {TRIGGER.SEVERITY}: {HOSTNAME1} {TRIGGER.STATUS}: {TRIGGER.NAME}'
      message "Trigger: {TRIGGER.NAME}\n"\
        "Trigger status: {TRIGGER.STATUS}\n" \
        "Trigger severity: {TRIGGER.SEVERITY}\n" \
        "\n" \
        "Item values:\n" \
        '{ITEM.NAME1} ({HOSTNAME1}:{TRIGGER.KEY1}): {ITEM.VALUE1}'
      media_type 'sms'
    end
  end

  condition :trigger_severity, :gte, :high
  condition :host_group, :equal, 'Main'
  condition :maintenance, :not_in, :maintenance
end

zabbix_user_macro 'Test_macro' do
  action :create
  value 'foobar'
end

zabbix_host 'Test_snmp_host' do
  type 2
  host_group 'Test group'
  port 161
  use_ip true
  ip_address '127.0.0.1'
end

zabbix_template 'Linux_Template' do
  host_name 'Test_snmp_host'
end

include_recipe 'zabbix_lwrp::connect'
