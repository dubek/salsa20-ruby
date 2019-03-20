require File.expand_path(File.join(File.dirname(__FILE__), "..", "lib", "salsa20"))
require 'minitest/autorun'

class Salsa20Test < MiniTest::Test
  def test_salsa20_keystream
    expected = "@\x8D\x94\xF48f9Z)\e\xBD\xB8?\xCC\xEC\xD6g\xB3;\xC7ev\v\xCA]\xEE\x19I;\xA2<\\^\xCEFQn\x94B{+\x06\xE2\x85\x9F\xEC\xBBp@\xA4\x8F\xD8~\xD3\x12\x197\f\xD7'\x8C\xC8\xEF\xFC"
    if expected.respond_to?(:force_encoding)
      expected.force_encoding(Encoding::ASCII_8BIT)
    end
    assert_equal expected, Salsa20.new("K"*32, "I"*8).encrypt("\x00"*64)
  end

  def test_bad_number_of_arguments_for_new_should_raise_exception
    assert_raises(ArgumentError) { Salsa20.new }
    assert_raises(ArgumentError) { Salsa20.new("K"*32) }
    assert_raises(ArgumentError) { Salsa20.new("K"*32, "I"*8, "third") }
  end

  def test_non_string_arguments_for_new_should_raise_exception
    assert_raises(TypeError) { Salsa20.new([1,2,3], "I"*8) }
    assert_raises(TypeError) { Salsa20.new("K"*32, { "a" => "b"}) }
    assert_raises(TypeError) { Salsa20.new([1,2,3], { "a" => "b"}) }
  end

  def test_invalid_key_length_should_raise_exception
    assert_raises(Salsa20::InvalidKeyError) { Salsa20.new("K"*15, "I"*8) }
    Salsa20.new("K"*16, "I"*8) # No exception
    assert_raises(Salsa20::InvalidKeyError) { Salsa20.new("K"*17, "I"*8) }
    assert_raises(Salsa20::InvalidKeyError) { Salsa20.new("K"*31, "I"*8) }
    Salsa20.new("K"*32, "I"*8) # No exception
    assert_raises(Salsa20::InvalidKeyError) { Salsa20.new("K"*33, "I"*8) }
  end

  def test_invalid_iv_length_should_raise_exception
    assert_raises(Salsa20::InvalidKeyError) { Salsa20.new("K"*32, "I"*7) }
    Salsa20.new("K"*32, "I"*8) # No exception
    assert_raises(Salsa20::InvalidKeyError) { Salsa20.new("K"*32, "I"*9) }
    assert_raises(Salsa20::InvalidKeyError) { Salsa20.new("K"*32, "I"*16) }
  end

  def test_accessors
    the_key = "K"*32
    the_iv = "I"*8
    encryptor = Salsa20.new(the_key, the_iv)
    assert_equal the_key, encryptor.key
    assert_equal the_iv, encryptor.iv
  end

  def test_encrypt_and_decrypt_with_256_bit_key
    the_key = "A"*32
    the_iv = "B"*8
    plain_text = "the quick brown fox jumped over the lazy dog"
    encryptor = Salsa20.new(the_key, the_iv)
    cipher_text = encryptor.encrypt(plain_text)
    assert_equal plain_text.size, cipher_text.size
    decryptor = Salsa20.new(the_key, the_iv)
    assert_equal plain_text, decryptor.decrypt(cipher_text)
  end

  def test_encrypted_encoding_should_be_binary
    return unless "TEST".respond_to?(:encoding)
    save_encoding = Encoding.default_external
    Encoding.default_external = "UTF-8"
    the_key = "A"*32
    the_iv = "B"*8
    plain_text = "the quick brown fox jumped over the lazy dog"
    encryptor = Salsa20.new(the_key, the_iv)
    cipher_text = encryptor.encrypt(plain_text)
    assert_equal Encoding.find("ASCII-8BIT"), cipher_text.encoding
    assert_equal Encoding.find("BINARY"), cipher_text.encoding
    Encoding.default_external = save_encoding
  end

  def test_encrypt_and_decrypt_with_128_bit_key
    the_key = "C"*16
    the_iv = "D"*8
    plain_text = "the quick brown fox jumped over the lazy dog"
    encryptor = Salsa20.new(the_key, the_iv)
    cipher_text = encryptor.encrypt(plain_text)
    assert_equal plain_text.size, cipher_text.size
    decryptor = Salsa20.new(the_key, the_iv)
    assert_equal plain_text, decryptor.decrypt(cipher_text)
  end

  def test_multiple_encrypt_and_one_decrypt
    the_key = "E"*32
    the_iv = "F"*8
    plain_text = "the quick brown fox jumped over the lazy dog" * 5
    parts = [ plain_text[0,64], plain_text[64,64], plain_text[128,64], plain_text[192,64] ]
    assert_equal plain_text, parts.join
    encryptor = Salsa20.new(the_key, the_iv)
    cipher_text = parts.map { |part| encryptor.encrypt(part) }.join
    assert_equal true, encryptor.closed?
    assert_equal plain_text.size, cipher_text.size
    decryptor = Salsa20.new(the_key, the_iv)
    assert_equal plain_text, decryptor.decrypt(cipher_text)
    assert_equal true, decryptor.closed?
  end

  def test_encrypt_after_non_64_bytes_should_raise_exception
    the_key = "G"*32
    the_iv = "H"*8
    part1 = "a"*63
    part2 = "b"*64
    encryptor = Salsa20.new(the_key, the_iv)
    assert_equal false, encryptor.closed?
    encryptor.encrypt(part1)
    assert_equal true, encryptor.closed?
    assert_raises(Salsa20::EngineClosedError) { encryptor.encrypt(part2) }
  end

  def test_seek
    the_key = "I"*32
    the_iv = "J"*8
    plain_text = "the quick brown fox jumped over the lazy dog" * 5
    encryptor = Salsa20.new(the_key, the_iv)
    cipher_text = encryptor.encrypt(plain_text)
    decryptor = Salsa20.new(the_key, the_iv)
    assert_equal 0, decryptor.position
    cipher_text.slice!(0,128)
    decryptor.seek(128)
    assert_equal 128, decryptor.position
    assert_equal plain_text[128..-1], decryptor.decrypt(cipher_text)
    assert_equal 256, decryptor.position
  end

  def test_seek_to_non_64_bytes_boundry_should_raise_exception
    the_key = "K"*32
    the_iv = "L"*8
    encryptor = Salsa20.new(the_key, the_iv)
    assert_raises(Salsa20::IllegalSeekError) { encryptor.seek(65) }
  end

  def test_seek_and_position_to_large_positions
    the_key = "M"*32
    the_iv = "N"*8
    large_position = 1 << 50
    encryptor = Salsa20.new(the_key, the_iv)
    assert_equal 0, encryptor.position
    encryptor.seek(large_position)
    assert_equal large_position, encryptor.position
  end

  # https://cr.yp.to/snuffle/salsafamily-20071225.pdf section 4.1
  def test_vector_from_salsa20_family_paper
    # From the paper:
    #
    #   For example, here is the starting array for key (1, 2, 3, 4, 5, ..., 32),
    #   nonce (3, 1, 4, 1, 5, 9, 2, 6), and block 7:
    #
    the_key = (1..32).to_a.pack("C*")
    the_iv = [3, 1, 4, 1, 5, 9, 2, 6].pack("C*")
    seek_block = 7

    encryptor = Salsa20.new(the_key, the_iv)
    encryptor.seek(seek_block * 64)
    # To obtain the keystream, encrypt a plaintext of zeroes:
    cipher_text = encryptor.encrypt("\x00" * 64)

    # The encrypted test vector from section 4.1:
    #
    #   0xb9a205a3, 0x0695e150, 0xaa94881a, 0xadb7b12c,
    #   0x798942d4, 0x26107016, 0x64edb1a4, 0x2d27173f,
    #   0xb1c7f1fa, 0x62066edc, 0xe035fa23, 0xc4496f04,
    #   0x2131e6b3, 0x810bde28, 0xf62cb407, 0x6bdede3d.
    #
    # The author presented it as little-endian words; here we treat it as
    # a string of bytes:
    expected = "\xa3\x05\xa2\xb9\x50\xe1\x95\x06\x1a\x88\x94\xaa\x2c\xb1\xb7\xad" +
      "\xd4\x42\x89\x79\x16\x70\x10\x26\xa4\xb1\xed\x64\x3f\x17\x27\x2d" +
      "\xfa\xf1\xc7\xb1\xdc\x6e\x06\x62\x23\xfa\x35\xe0\x04\x6f\x49\xc4" +
      "\xb3\xe6\x31\x21\x28\xde\x0b\x81\x07\xb4\x2c\xf6\x3d\xde\xde\x6b"
    expected.force_encoding(Encoding::BINARY)
    assert_equal expected, cipher_text
  end
end
