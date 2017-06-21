# Encoding: ASCII-8BIT
require 'test_helper'

require 'dnscat2/core/dns/packer'

module DNSer
  class PackerTest < ::Test::Unit::TestCase
    def test_pack()
      packer = Packer.new()
      packer.pack('NnC', 0x41424344, 0x4546, 0x47)
      assert_equal('ABCDEFG', packer.get())
    end

    def test_pack_name_single_segment()
      packer = Packer.new()
      packer.pack_name('test')
      assert_equal("\x04test\x00", packer.get())
    end

    def test_pack_name()
      packer = Packer.new()
      packer.pack('N', 0x41424344)
      packer.pack('n', 0x4546)
      packer.pack('C', 0x47)
      packer.pack_name('test.com')
      assert_equal("ABCDEFG\x04test\x03com\x00", packer.get())
    end

    def test_pack_name_that_ends_with_period()
      packer = Packer.new()
      packer.pack_name('test.com.')
      assert_equal("\x04test\x03com\x00", packer.get())
    end

    def test_pack_name_pointer()
      packer = Packer.new()
      packer.pack('N', 0x41424344)
      packer.pack_name('test.com')
      packer.pack_name('test.com')
      assert_equal("ABCD\x04test\x03com\x00\xc0\x04", packer.get())
    end

    def test_pack_name_partial_pointer()
      packer = Packer.new()
      packer.pack('N', 0x41424344)
      packer.pack_name('www.test.com')
      packer.pack_name('test.com')
      assert_equal("ABCD\x03www\x04test\x03com\x00\xc0\x08", packer.get())

      packer = Packer.new()
      packer.pack('N', 0x41424344)
      packer.pack_name('test.com')
      packer.pack_name('www.test.com')
      assert_equal("ABCD\x04test\x03com\x00\x03www\xc0\x04", packer.get())
    end

    def test_pack_name_double_pointer()
      packer = Packer.new()
      packer.pack_name('server.www.test.com')
      packer.pack_name('www.test.com')
      packer.pack_name('other.www.test.com')
      packer.pack_name('test.com')

      expected = "\x06server\x03www\x04test\x03com\x00" +
        "\xc0\x07" +
        "\x05other\xc0\x07" +
        "\xc0\x0b"
      assert_equal(expected, packer.get())

      packer = Packer.new()
      packer.pack_name('test.com')
      packer.pack_name('other.www.test.com')
      packer.pack_name('www.test.com')
      packer.pack_name('server.www.test.com')

      expected = "\x04test\x03com\x00" +
        "\x05other\x03www\xc0\x00" +
        "\xc0\x10" +
        "\x06server\xc0\x10"
      assert_equal(expected, packer.get())
    end

    def test_pack_illegal_name()
      packer = Packer.new()

      assert_raises(FormatException) do
        packer.pack_name('test..com')
      end
      assert_raises(FormatException) do
        packer.pack_name('te\x00st.com')
      end
    end

    def test_pack_name_segment_too_long()
      packer = Packer.new()

      name = ('A' * 63) + '.com'
      packer.pack_name(name)
      assert_raises(FormatException) do
        packer.pack_name('A' + name)
      end
    end

    def test_pack_name_too_long()
      packer = Packer.new()

      # This makes it 256
      name = ([('A' * 31)] * 8).join('.')

      # This makes it 253, the exact maximum
      name = name[2..-1]

      # Verify it works with 253...
      packer.pack_name(name)

      # ...but fails with 254
      assert_raises(FormatException) do
        packer.pack_name('A' + name)
      end
    end
  end
end