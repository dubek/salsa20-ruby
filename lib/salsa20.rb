require 'salsa20_ext'

# Salsa20 stream cipher engine. Initialize the engine with +key+ and +iv+, and
# then call Salsa20#encrypt or Salsa20#decrypt (they are actually identical --
# that's how stream ciphers work).
#
# Example:
#
#   encryptor = Salsa20.new(key_str, iv_str)
#   cipher_text = encryptor.encrypt(plain_text)
#
class Salsa20

  # Salsa20 engine was initialized withe a key of the wrong length (see Salsa20#new).
  class InvalidKeyError < StandardError
  end

  # Salsa20#encrypt was called after a non 64-bytes boundry block
  class EngineClosedError < StandardError
  end

  # Salsa20#seek was called with a non 64-bytes boundry position
  class IllegalSeekError < StandardError
  end

  # The encryption key
  attr_reader :key

  # The encryption IV (Initialization Vector) / nonce
  attr_reader :iv

  # Create a new Salsa20 encryption/decryption engine.
  #
  # +key+ is the encryption key and must be exactly 128-bits (16 bytes) or
  # 256-bits (32 bytes) long
  #
  # +iv+ is the encryption IV and must be exactly 64-bits (8 bytes) long
  #
  # If +key+ or +iv+ lengths are invalid then a Salsa20::InvalidKeyError
  # exception is raised.
  def initialize(key, iv)
    # do all the possible checks here to make sure the C extension code gets clean variables
    raise TypeError, "key must be a String" unless key.is_a? String
    raise TypeError, "iv must be a String" unless iv.is_a? String

    raise InvalidKeyError, "key length must be 16 or 32 bytes" unless key.size == 16 || key.size == 32
    raise InvalidKeyError, "iv length must be 8 bytes" unless iv.size == 8

    @key = key
    @iv = iv
    @closed = false
    init_context # Implemented in the C extension
  end

  # Returns _true_ if the last encryption was of a non 64-bytes boundry chunk.
  # This means this instance cannot be further used (subsequent calls to
  # Salsa20#encrypt or Salsa20#decrypt will raise a Salsa20::EngineClosedError
  # exception); _false_ if the instance can be further used to encrypt/decrypt
  # additional chunks.
  def closed?
    @closed
  end

  # Encrypts/decrypts the string +input+. If +input+ length is on 64-bytes
  # boundry, you may call encrypt (or decrypt) again; once you call it with a
  # non 64-bytes boundry chunk this must be the final chunk (subsequent calls will
  # raise a Salsa20::EngineClosedError exception).
  #
  # Returns the encrypted/decrypted string, which has the same size as the
  # input string.
  def encrypt(input)
    raise TypeError, "input must be a string" unless input.is_a? String
    raise EngineClosedError, "instance is closed" if closed?
    @closed = true if (input.size % 64) != 0
    encrypt_or_decrypt(input) # Implemented in the C extension
  end

  alias :decrypt :encrypt

  # Advance the cipher engine into +position+ (given in bytes). This can be
  # used to start decrypting from the middle of a file, for example.
  #
  # Note: +position+ must be on a 64-bytes boundry (otherwise a
  # Salsa20::IllegalSeekError exception is raised).
  def seek(position)
    raise IllegalSeekError, "seek position must be on 64-bytes boundry" unless position % 64 == 0
    position /= 64
    set_cipher_position(low_32bits(position), high_32bits(position)) # Implemented in the C extension
  end

  # Returns the current cipher stream position in bytes
  def position
    get_cipher_position * 64
  end

  private

  def low_32bits(n)
    n & 0xffffffff
  end

  def high_32bits(n)
    (n >> 32) & 0xffffffff
  end
end
