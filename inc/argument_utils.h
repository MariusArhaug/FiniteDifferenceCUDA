#ifndef _ARGUMENT_UTILS_H_
#define _ARGUMENT_UTILS_H_

#include <stdint.h>


typedef int64_t int_t;

typedef struct options_struct {
    int_t N;
    int_t max_iteration;
    int_t snapshot_frequency;
} OPTIONS;


OPTIONS *parse_args ( int argc, char **argv );

void help ( char const *exec, char const opt, char const *optarg );

#endif
