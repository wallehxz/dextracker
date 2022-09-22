class Notice
  class << self

    def tip(content = '内容')
      push_url = "https://oapi.dingtalk.com/robot/send?access_token=28310a70673b9fbcec9d368a34ca5138167d3a09f553f925da2f3caacc007626"
      body_params ={ msgtype:'text', text:{ content: '【通知】' + content } }
      res = Faraday.post do |req|
        req.url push_url
        req.headers['Content-Type'] = 'application/json'
        req.body = body_params.to_json
      end
    end

    def alarm(content = '内容')
      push_url = "https://oapi.dingtalk.com/robot/send?access_token=28310a70673b9fbcec9d368a34ca5138167d3a09f553f925da2f3caacc007626"
      body_params ={ msgtype:'text', text:{ content: '【异常】' + content } }
      res = Faraday.post do |req|
        req.url push_url
        req.headers['Content-Type'] = 'application/json'
        req.body = body_params.to_json
      end
    end

    def exception(ex, mark = "Application")
      path = Rails.root.to_s
      log = ex.backtrace.select { |l| l.include? path }.map {|l| l.gsub(path,'')}.join("\n")
      push_url = "https://oapi.dingtalk.com/robot/send?access_token=28310a70673b9fbcec9d368a34ca5138167d3a09f553f925da2f3caacc007626"
      content =
        "#{mark} 异常\n\n" +
        "> 类型： #{ex.message}\n" +
        "> 时间： #{Time.now.to_s(:short)}\n" +
        "> 日志： \n#{log}"
      body_params ={ msgtype:'text', text:{ content: content } }
      res = Faraday.post do |req|
        req.url push_url
        req.headers['Content-Type'] = 'application/json'
        req.body = body_params.to_json
      end
    end

    def wechat(content = '内容')
      push_url = "http://wxpusher.zjiecode.com/api/send/message"
      body_params ={}
      body_params['appToken'] = 'AT_0l9soo2UqtyitwRZSBpJyUAlr0uF3J1F'
      body_params['content'] = content
      body_params['contentType'] = 1
      body_params['topicIds'] = [7519]
      res = Faraday.post do |req|
        req.url push_url
        req.headers['Content-Type'] = 'application/json'
        req.body = body_params.to_json
      end
    end

  end
end
