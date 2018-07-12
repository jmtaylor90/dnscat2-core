# Encoding: ASCII-8BIT
require 'test_helper'

require 'dnscat2/core/dnscat_exception'
require 'dnscat2/core/tunnel_drivers/encoders/base32'
require 'dnscat2/core/tunnel_drivers/encoders/hex'

require 'dnscat2/core/tunnel_drivers/dns/mx_encoder'

module Dnscat2
  module Core
    module TunnelDrivers
      module DNS
        class NameHelperTest < ::Test::Unit::TestCase
          def test_mx_normal()
            encoder = MXEncoder.new(
              tag: nil,
              domain: nil,
              max_subdomain_length: 63,
              encoder: Encoders::Hex,
            )

            rr = encoder.encode(data: 'AAAA').pop()

            assert_equal('41414141', rr.name)
          end

          def test_mx_with_tag()
            encoder = MXEncoder.new(
              tag: 'aaa',
              domain: nil,
              max_subdomain_length: 63,
              encoder: Encoders::Hex,
            )

            rr = encoder.encode(data: 'AAAA').pop()

            assert_equal('aaa.41414141', rr.name)
          end

          def test_mx_with_domain()
            encoder = MXEncoder.new(
              tag: nil,
              domain: 'aaa',
              max_subdomain_length: 63,
              encoder: Encoders::Hex,
            )

            rr = encoder.encode(data: 'AAAA').pop()

            assert_equal('41414141.aaa', rr.name)
          end

          def test_mx_with_different_subdomain_length()
            encoder = MXEncoder.new(
              tag: nil,
              domain: nil,
              max_subdomain_length: 3,
              encoder: Encoders::Hex,
            )

            rr = encoder.encode(data: 'AAAA').pop()

            assert_equal('414.141.41', rr.name)
          end

          def test_mx_with_different_encoder()
            encoder = MXEncoder.new(
              tag: nil,
              domain: nil,
              max_subdomain_length: 63,
              encoder: Encoders::Base32,
            )

            rr = encoder.encode(data: 'AAAA').pop()

            assert_equal('ifaucqi', rr.name)
          end

          def test_mx_with_just_less_than_too_much_data()
            encoder = MXEncoder.new(
              tag: nil,
              domain: nil,
              max_subdomain_length: 63,
              encoder: Encoders::Hex,
            )

            rr = encoder.encode(data: 'A' * encoder.max_length()).pop()
            assert_not_nil(rr)
            assert_not_nil(rr.name)
          end

          def test_mx_with_too_much_data()
            encoder = MXEncoder.new(
              tag: nil,
              domain: nil,
              max_subdomain_length: 63,
              encoder: Encoders::Hex,
            )

            assert_raises(DnscatException) do
              encoder.encode(data: 'A' * (encoder.max_length() + 1)).pop()
            end
          end

          def test_mx_with_just_less_than_too_much_data_and_a_domain()
            encoder = MXEncoder.new(
              tag: nil,
              domain: 'aaaaaaaaaaaaaaaaa',
              max_subdomain_length: 10,
              encoder: Encoders::Hex,
            )

            rr = encoder.encode(data: 'A' * encoder.max_length()).pop()
            assert_not_nil(rr)
            assert_not_nil(rr.name)
          end

          def test_mx_with_too_much_data_and_a_domain()
            encoder = MXEncoder.new(
              tag: nil,
              domain: 'aaaaaaaaaaaaaaaaa',
              max_subdomain_length: 10,
              encoder: Encoders::Hex,
            )

            assert_raises(DnscatException) do
              encoder.encode(data: 'A' * (encoder.max_length() + 1))
            end
          end
        end
      end
    end
  end
end