# Copyright (c) 2008-2009 The Rubyists, LLC (effortless systems) <rubyists@rubyists.com>
# Distributed under the terms of the MIT license.
# The full text can be found in the LICENSE file included with this software
#
module FXC
  module Rack
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        params = ::Rack::Request.new(env)
        if params["section"]
          path = params["section"] + "/"

          path << case path
          when "dialplan/"
            dp_req(params)
          when "directory/"
            dir_req(params)
          when "configuration/"
            conf_req(params)
          end

          path << "/#{params["hostname"]}"
          env["PATH_INFO"] = "#{env['PATH_INFO']}/#{path}".squeeze('/').sub(%r{/$},'')
=begin
          env["REQUEST_URI"] = ("%s://%s/%s" % [
            env["rack.url_scheme"],
            env["HTTP_HOST"],
            env["PATH_INFO"]]).squeeze('/')
=end
        end
        @app.call(env)
      end

      private
      def dp_req(params)
        s = [params["Caller-Context"]]
        s << params["Caller-Destination-Number"]
        s << params["Caller-Caller-ID-Number"]
        s.compact.join("/")
      end

      def dir_req(params)
        s = []
        if params["purpose"]
          s << params["purpose"].gsub("-","_")
          s << params["sip_profile"]
        elsif params["action"] && params["action"] == "sip_auth"
          s << "register"
          s << params["sip_profile"]
          s << params["sip_auth_username"]
        elsif params["user"]
          if params["action"] == "message-count"
            s << "messages"
            s << params["user"]
            s << params["key_value"] if params["tag_name"] == "domain"
          elsif params["Event-Calling-Function"]
            case params["Event-Calling-Function"].to_s
            when /voicemail/
              s << "voicemail"
              s << (params["sip_profile"] || "default")
              s << params["user"]
            when "user_outgoing_channel"
              s << "user_outgoing"
              s << params["user"]
              s << params["domain"] if params["domain"]
            when "user_data_function"
              s << "user_data"
              s << params["user"]
              s << params["domain"] if params["domain"]
            end
          end
        end
        s.join("/")
      end

      def conf_req(params)
        s = []
        if params["key_name"] == "name"
          s << params["key_value"]
        end
        s.join("/")
      end

    end
  end
end
