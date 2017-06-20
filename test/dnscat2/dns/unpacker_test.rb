# Encoding: ASCII-8BIT
require 'test_helper'

require 'dnscat2/core/dns/unpacker'

module DNSer
  class UnpackerTest < ::Test::Unit::TestCase
    def test_unpack()
      unpacker = Unpacker.new("AAAABBC")

      # I don't actually want to test the 'unpack' format, since that's a Ruby
      # feature that we can safely trust, so I'm only going to use basic stuff.
      a, b, c = unpacker.unpack("NnC")
      assert_equal(0x41414141, a)
      assert_equal(0x4242, b)
      assert_equal(0x43, c)
    end

    def test_multiple_unpack()
      unpacker = Unpacker.new("AAAABBC")

      a = unpacker.unpack_one("N")
      assert_equal(0x41414141, a)

      b = unpacker.unpack_one("n")
      assert_equal(0x4242, b)

      c = unpacker.unpack_one("C")
      assert_equal(0x43, c)
    end

    def test_unpack_one_unpack_too_many()
      unpacker = Unpacker.new("AAAABBC")

      assert_raises(FormatException) do
        unpacker.unpack_one("NN")
      end
    end

    def test_unpack_truncated()
      # Between fields
      unpacker = Unpacker.new("AAAA")
      assert_raises(FormatException) do
        unpacker.unpack("Nn")
      end

      # Within a field
      unpacker = Unpacker.new("AAA")
      assert_raises(FormatException) do
        unpacker.unpack("N")
      end

      # Empty string
      unpacker = Unpacker.new("")
      assert_raises(FormatException) do
        unpacker.unpack("N")
      end
    end

    def test_unpack_name()
      unpacker = Unpacker.new("AAAABBC\x04test\x00")

      unpacker.unpack("NnC")
      name = unpacker.unpack_name()

      assert_equal('test', name)
    end

    def test_unpack_name_multiple_segments()
      unpacker = Unpacker.new("AAAABBC\x04test\x08testtest\x00")

      unpacker.unpack("NnC")
      name = unpacker.unpack_name()

      assert_equal('test.testtest', name)
    end

    def test_unpack_name_zero_length()
      unpacker = Unpacker.new("AAAABBC\x00")

      unpacker.unpack("NnC")
      name = unpacker.unpack_name()

      assert_equal('', name)
    end

    def test_unpack_name_with_reference()
      unpacker = Unpacker.new("\x01A\x00\x00\x04name\xc0\x00")

      # "eat" the first string so we can reference it later
      unpacker.unpack("N")
      name = unpacker.unpack_name()

      assert_equal('name.A', name)
    end

    def test_unpack_with_forward_reference()
      unpacker = Unpacker.new("\x02AA\xc0\x05\x04name\x00")

      # "eat" the first string so we can reference it later
      name = unpacker.unpack_name()

      assert_equal('AA.name', name)
    end

    def test_unpack_name_with_zero_length_segment()
      unpacker = Unpacker.new("\xc0\x02\x04name\x00")

      # "eat" the first string so we can reference it later
      name = unpacker.unpack_name()

      assert_equal('name', name)
    end

    def test_unpack_name_truncated()
      # No pointers
      assert_raises(FormatException) do
        Unpacker.new("\x04name").unpack_name()
      end
      assert_raises(FormatException) do
        Unpacker.new("\x04na").unpack_name()
      end
      assert_raises(FormatException) do
        Unpacker.new("\x04").unpack_name()
      end
      assert_raises(FormatException) do
        Unpacker.new("").unpack_name()
      end

      # Pointers
      assert_raises(FormatException) do
        Unpacker.new("\xc0\x04AA\x04test").unpack_name()
      end
      assert_raises(FormatException) do
        Unpacker.new("\xc0\x04AA\x04tes").unpack_name()
      end
      assert_raises(FormatException) do
        Unpacker.new("\xc0\x04AA\x04te").unpack_name()
      end
      assert_raises(FormatException) do
        Unpacker.new("\xc0\x04AA\x04t").unpack_name()
      end
      assert_raises(FormatException) do
        Unpacker.new("\xc0\x04AA\x04").unpack_name()
      end
      assert_raises(FormatException) do
        Unpacker.new("\xc0\x04AA").unpack_name()
      end
      assert_raises(FormatException) do
        Unpacker.new("\xc0\x04A").unpack_name()
      end
      assert_raises(FormatException) do
        Unpacker.new("\xc0\x04").unpack_name()
      end
      assert_raises(FormatException) do
        Unpacker.new("\xc0").unpack_name()
      end
    end

    def test_unpack_bad_negative_reference()
      # This will never come up in real DNS, but I might as well test the extreme edgecase
      unpacker = Unpacker.new(("\xFF" * 0x3FFF) + "\x04name\x00")

      name = unpacker.unpack_name()
      assert_equal('name', name)
    end

    def test_unpack_infinite_loop()
      unpacker = Unpacker.new("\x01A\x00\x00\x04name\xc0\x04")

      # "eat" the first string so we can reference it later
      unpacker.unpack("N")

      assert_raises(FormatException) do
        unpacker.unpack_name()
      end
    end
  end

  class PackerTest < ::Test::Unit::TestCase
    def test_pack()
      name = Packer.pack_name('test')
      assert_equal("\x04test\x00", name)
    end

    def test_pack_multiple_segments()
      name = Packer.pack_name('test.com')
      assert_equal("\x04test\x03com\x00", name)
    end

    def test_pack_zero_length()
      name = Packer.pack_name('')
      assert_equal("\x00", name)
    end

    def test_pack_with_double_dot()
      assert_raises(FormatException) do
        Packer.pack_name('test..com')
      end
    end

    def test_with_illegal_character()
      assert_raises(FormatException) do
        Packer.pack_name('te\x00st.com')
      end
    end

    def test_segment_too_long()
      name = ('A' * 63) + '.com'
      Packer.pack_name(name)
      assert_raises(FormatException) do
        Packer.pack_name('A' + name)
      end
    end

    def test_packet_too_long()
      # This makes it 256
      name = (('A' * 31) + '.') * 8

      # This makes it 253, the exact maximum
      name = name[3..-1]

      # Verify it works with 253...
      Packer.pack_name(name)

      # ...but fails with 254
      assert_raises(FormatException) do
        Packer.pack_name('A' + name)
      end
    end
  end
end
