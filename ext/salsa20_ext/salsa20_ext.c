#include <ruby.h>
#include "ecrypt-sync.h"

/* Older versions of Ruby (< 1.8.6) need these */
#ifndef RSTRING_PTR
#define RSTRING_PTR(s) (RSTRING(s)->ptr)
#endif
#ifndef RSTRING_LEN
#define RSTRING_LEN(s) (RSTRING(s)->len)
#endif
#ifndef RARRAY_PTR
#define RARRAY_PTR(s) (RARRAY(s)->ptr)
#endif
#ifndef RARRAY_LEN
#define RARRAY_LEN(s) (RARRAY(s)->len)
#endif

static VALUE cSalsa20;

static VALUE rb_salsa20_alloc(VALUE klass) {
    VALUE obj;
    ECRYPT_ctx *ctx;

    obj = Data_Make_Struct(klass, ECRYPT_ctx, 0, 0, ctx);
    return obj;
}

static VALUE rb_salsa20_init_context(VALUE self) {
    VALUE key, iv;
    ECRYPT_ctx *ctx;

    Data_Get_Struct(self, ECRYPT_ctx, ctx);
    key = rb_iv_get(self, "@key");
    iv = rb_iv_get(self, "@iv");

    ECRYPT_keysetup(ctx, (const unsigned char*)RSTRING_PTR(key), (unsigned int)RSTRING_LEN(key) * 8, 64);
    ECRYPT_ivsetup(ctx, (const unsigned char*)RSTRING_PTR(iv));

    return self;
}

static VALUE rb_salsa20_encrypt_or_decrypt(int argc, VALUE * argv, VALUE self) {
    VALUE input, output;
    ECRYPT_ctx *ctx;

    Data_Get_Struct(self, ECRYPT_ctx, ctx);

    rb_scan_args(argc, argv, "1", &input);
    Check_Type(input, T_STRING);

    output = rb_str_new(0, RSTRING_LEN(input));
    ECRYPT_encrypt_bytes(ctx, (const unsigned char*)RSTRING_PTR(input), (unsigned char*)RSTRING_PTR(output), (unsigned int)RSTRING_LEN(input));

    return output;
}

static VALUE rb_salsa20_set_cipher_position(int argc, VALUE * argv, VALUE self) {
    VALUE low_32bits, high_32bits;
    ECRYPT_ctx *ctx;

    Data_Get_Struct(self, ECRYPT_ctx, ctx);

    rb_scan_args(argc, argv, "2", &low_32bits, &high_32bits);
    ctx->input[8] = NUM2INT(low_32bits);
    ctx->input[9] = NUM2INT(high_32bits);

    return Qnil;
}

static VALUE rb_salsa20_get_cipher_position(VALUE self) {
    ECRYPT_ctx *ctx;

    Data_Get_Struct(self, ECRYPT_ctx, ctx);

    return rb_ull2inum(((unsigned LONG_LONG)(ctx->input[9]) << 32) | (unsigned LONG_LONG)(ctx->input[8]));
}

void Init_salsa20_ext() {
    cSalsa20 = rb_define_class("Salsa20", rb_cObject);

    rb_define_alloc_func(cSalsa20, rb_salsa20_alloc);

    rb_define_private_method(cSalsa20, "init_context", rb_salsa20_init_context, 0);
    rb_define_private_method(cSalsa20, "encrypt_or_decrypt", rb_salsa20_encrypt_or_decrypt, -1);
    rb_define_private_method(cSalsa20, "set_cipher_position", rb_salsa20_set_cipher_position, -1);
    rb_define_private_method(cSalsa20, "get_cipher_position", rb_salsa20_get_cipher_position, 0);
}
