# encoding: utf-8

require 'rubygems'
require 'json'
require 'win32ole'
#require 'watir'


#访问一次网站并记录访问时间
def access_page(web_name)
  @a = 0
  @ZX_times += 1
  begin
    ieBrowser = WIN32OLE.new('InternetExplorer.Application')
    ieBrowser.Visible = true
    control = WIN32OLE.new("HttpWatch.Controller")
    plugin = control.IE.Attach(ieBrowser)
    plugin.Log.EnableFilter(false)
    plugin.ClearCache()
    plugin.Clear()
    plugin.Record()
    #ieBrowser.navigate(web_name)
    #sleep(5) until ieBrowser.busy == false
    plugin.GotoUrl(web_name)
    #最多只等待30s
    control.Wait(plugin, 30)
  rescue
    puts "浏览器窗口打开异常"
    @YC_times += 1
    @a += 1
    #ensure
    # plugin.Stop()
  end
  puts @a
  #此处加入异常处理当测试环境加载失败时直接返回nil，ruby在rescue里面无法return
  return nil if @a == 1
  ip = plugin.log.Entries.Item(0).ServerIP
  puts "本次访问网页的IP是#{ip.chomp}"
  code = plugin.Log.Entries.Item(0).StatusCode
  if code == 200 or code == 301 or code == 302 or code == 303
    time_elapsed = plugin.Log.Entries.Summary.Time
    puts "本次访问网页花费的时间 = #{time_elapsed}"
  else
    puts "本次访问网页失败"
    @fail_times += 1
  end
  ieBrowser.quit
  return time_elapsed
end

#循环访问网站并统计结果
def access_times(web_name, times)
  @fail_times = 0
  @ZX_times = 0
  @YC_times = 0
  time_array = []
  times.to_i.times do
    time_array << access_page(web_name)
    #去除数组中值为nil的元素
    @time_eclipsed = calculate_average(time_array.compact)
    @access_times = @ZX_times.to_i - @fail_times.to_i - @YC_times.to_i
    puts "##########################################"
    puts "#访问的网站是#{web_name.chomp}"
    puts "#总共尝试访问#{@ZX_times}次,环境加载异常#{@YC_times},访问失败#{@fail_times}次#"
    puts "#成功访问网页#{@access_times.abs}次的平均值是#{@time_eclipsed.round(3)}          #"
    puts "##########################################"
    sleep 5
  end
  #将单个网站测试结果记录到D盘根目录
  txt_name1 = web_name.delete "://."
  txt_name = txt_name1.chomp.insert(-1, '.txt')
  aFile = File.new("D:\\#{txt_name}", "w")
  aFile.puts "##########################################"
  aFile.puts "#访问的网站是#{web_name.chomp}"
  aFile.puts "#总共尝试访问#{@ZX_times}次,环境加载异常#{@YC_times},访问失败#{@fail_times}次#"
  aFile.puts "#成功访问网页#{@access_times.abs}次的平均值是#{@time_eclipsed.round(3)}          #"
  aFile.puts "##########################################"
  aFile.close
end

#算出成功访问网站延时的平均值
def calculate_average(param_array)
  return 0 if param_array.nil?
  return 0 if param_array.size <= 0
  return param_array[0].to_f if param_array.size == 1
  min = param_array[0].to_f
  max = param_array[0].to_f
  sum_num = param_array.length - 1
  for i in 1..sum_num
    if param_array[i].to_f >= max
      max = param_array[i].to_f
    elsif param_array[i].to_f <= min
      min = param_array[i].to_f
    end
  end
  sum = 0
  for i in 0..sum_num
    numuber = param_array[i].to_f
    sum += numuber
  end
  if param_array.size > 2
    sum = sum - max - min
    sum_num = param_array.length - 2
  else
    sum_num = param_array.length
  end
  avg = sum.to_f / sum_num.to_f
  #puts "#{param_array.join(',')}的平均值是: #{avg}"
  return avg
end

puts "#################################"
puts "#            wellcome           #"
puts "#################################"
puts "请输入执行次数"
times =gets
#读取配置文件C:\\name.txt，遍历文件中的域名
File.open("C:\\name.txt") do |io|
  io.each_line do |line|
    access_times(line, times)
  end
end
