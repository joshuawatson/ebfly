require "thor"
require "aws-sdk"
require "pp"
require "open3"

module Ebfly
  module Command
    PREDEFINED_SOLUTION_STACKS = {
      "php53"    => "64bit Amazon Linux running PHP 5.3",
      "php54"    => "64bit Amazon Linux 2013.09 running PHP 5.4",
      "php55"    => "64bit Amazon Linux 2013.09 running PHP 5.5",
      "nodejs"   => "64bit Amazon Linux 2013.09 running Node.js",
      "java7"    => "64bit Amazon Linux 2013.09 running Tomcat 7 Java 7",
      "java6"    => "64bit Amazon Linux 2013.09 running Tomcat 7 Java 6",
      "python27" => "64bit Amazon Linux 2013.09 running Python 2.7",
      "ruby18"   => "64bit Amazon Linux 2013.09 running Ruby 1.8.7",
      "ruby19"   => "64bit Amazon Linux 2013.09 running Ruby 1.9.3",
    }

    def eb
      @eb ||= AWS::ElasticBeanstalk.new
      @eb.client
    end

    def s3
      @s3 ||= AWS::S3.new
    end

    def run(&block)
      begin
        res = yield
        raise res.error unless res.successful?
        res
      rescue => err
        style_err(err)
        exit 1
      end
    end

    def s3_bucket
      @s3_bucket ||= (run { eb.create_storage_location }[:s3_bucket])
    end

    def style_err(err)
      puts "ERR! #{err.message}" 
    end

    def debug(obj)
      pp obj if ENV["DEBUG"]
    end

    def exist_command?(cmd)
      Open3.capture3("type", cmd)[2].exitstatus == 0 rescue nil
    end

    def env_name(app, env)
      "#{app}-#{env}"
    end

    def tier(type)
      if type == "web"
        return { name: "WebServer", type: "Standard", version: "1.0" }
      elsif type == "worker"
        return { name: "Worker", type: "SQS/HTTP", version: "1.0" }
      else
        raise "Environment tier definition not found"
      end
    end

    def solution_stack(name)
      return PREDEFINED_SOLUTION_STACKS[name] if PREDEFINED_SOLUTION_STACKS.key?(name)
      return name
    end
  end
end
