# Encoding: ASCII-8BIT
require 'test_helper'

require 'dnscat2/core/dnscat_exception'
require 'dnscat2/core/tunnel_drivers/encoders/base32'

require 'dnscat2/core/tunnel_drivers/dns/builders/aaaa'

module Dnscat2
  module Core
    module TunnelDrivers
      module DNS
        module Builders
          class AAAATest < ::Test::Unit::TestCase
            def setup()
              @builder = AAAA.new(tag: 'abc', domain: 'def')
            end

            def test_encode_blank()
              #rr = @builder.build(data: '').pop()
              #assert_equal('', rr.data)
            end

            def test_encode_some_bytes()
              rrs = @builder.build(data: "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
              assert_equal(2, rrs.length)
              assert_equal("1a:4142:4344:4546:4748:494a:4b4c:4d4e", rrs[0].address.to_s)
              assert_equal("14f:5051:5253:5455:5657:5859:5aff:ffff", rrs[1].address.to_s)
            end

            def test_encode_some_bytes_with_nuls()
              rrs = @builder.build(data: "ABCDEFGHIJKLMNO\0\0\0\0\0\0\0\0\0\0\0")
              assert_equal(2, rrs.length)
              assert_equal("1a:4142:4344:4546:4748:494a:4b4c:4d4e", rrs[0].address.to_s)
              assert_equal("14f::ff:ffff", rrs[1].address.to_s)
            end

            def test_encode_one_byte()
              rrs = @builder.build(data: "A")
              assert_equal(1, rrs.length)
              assert_equal("1:41ff:ffff:ffff:ffff:ffff:ffff:ffff", rrs[0].address.to_s)
            end

            def test_encode_one_ip()
              rrs = @builder.build(data: "AAAAAAAAAAAAAA")
              assert_equal(1, rrs.length)
              assert_equal("e:4141:4141:4141:4141:4141:4141:4141", rrs[0].address.to_s)
            end

            def test_encode_max_bytes()
              rrs = @builder.build(data: "A" * (@builder.max_length()))
              assert_equal(15, rrs.length)
              assert_equal("e0:4141:4141:4141:4141:4141:4141:4141", rrs[0].address.to_s)
              1.upto(14) do |i|
                assert_equal("%x41:4141:4141:4141:4141:4141:4141:4141" % i, rrs[i].address.to_s)
              end
            end

            def test_encode_max_bytes_plus_one()
              assert_raises(DnscatException) do
                @builder.build(data: "A" * (@builder.max_length() + 1))
              end
            end
          end
        end
      end
    end
  end
end
