#include <gmp.h>

extern "C" {
    void add_big_numbers(const char* num1, const char* num2, char* result, size_t result_size) {
        mpz_t a, b, sum;
        mpz_init(a);
        mpz_init(b);
        mpz_init(sum);

        mpz_set_str(a, num1, 10);
        mpz_set_str(b, num2, 10);

        mpz_add(sum, a, b);

        mpz_get_str(result, 10, sum);

        mpz_clear(a);
        mpz_clear(b);
        mpz_clear(sum);
    }
}
