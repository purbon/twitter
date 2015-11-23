require 'http/parser'
require 'openssl'
require 'resolv'

module Twitter
  module Streaming
    class Connection
      attr_reader :tcp_socket_class, :ssl_socket_class

      def initialize(options = {})
        @tcp_socket_class = options.fetch(:tcp_socket_class) { TCPSocket }
        @ssl_socket_class = options.fetch(:ssl_socket_class) { OpenSSL::SSL::SSLSocket }
        @use_ssl          = options.fetch(:use_ssl) { false }
      end

      def stream(request, response)
        socket = @tcp_socket_class.new(Resolv.getaddress(request.socket_host), request.socket_port)
        if !request.using_proxy? || (request.using_proxy? && @use_ssl)
          socket = ssl_stream(socket)
        end

        request.stream(socket)
        while body = socket.readpartial(1024) # rubocop:disable AssignmentInCondition
          response << body
        end
      end

      private

      def ssl_stream(client)
        client_context = OpenSSL::SSL::SSLContext.new
        ssl_client     = @ssl_socket_class.new(client, client_context)
        ssl_client.connect
      end
    end
  end
end
