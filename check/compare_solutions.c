#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <sys/stat.h>
#include <stdint.h>
#include <stdbool.h>
#include <math.h>


const double epsilon = 1e-4;


void load_solution ( char *filename, double *data, int64_t N );
uint64_t compare_solutions ( double *solution, double *other_solution, int64_t N );


int main ( int argc, char **argv )
{
    assert ( argc > 3 );

    int64_t N = pow ( atoi(argv[1]), 2 );

    double *solution_1 = malloc ( N * sizeof(double) );
    double *solution_2 = malloc ( N * sizeof(double) );

    load_solution ( argv[2], solution_1, N );
    load_solution ( argv[3], solution_2, N );

    uint64_t errors = compare_solutions ( solution_1, solution_2, N );
    fprintf ( stderr, "There are %ld differences between the solution and the reference solution\n", errors );

    free ( solution_1 );
    free ( solution_2 );

    return 0;
}


size_t
get_file_size( char *filename )
{
    struct stat properties;
    if ( stat( filename, &properties ) == -1 )
    {
        exit(1);
    }

    return properties.st_size;
}


void
load_solution ( char* filename, double *solution, int64_t N )
{
    FILE *in = fopen( filename, "rb" );
    if ( !in )
    {
        fprintf ( stderr, "Failed to open file: %s\n", filename );
        exit(1);
    }

    size_t file_size = get_file_size ( filename );
    if ( file_size != (N * sizeof(double)) )
    {
        fprintf ( stderr, "Expected solution size does not match actual solution size\n" );
        exit(1);
    }

    size_t read = fread ( solution, file_size, 1, in );
    if ( read != 1 )
    {
        fprintf( stderr, "Error occured while reading solution\n" );
        exit(1);
    }

    fclose ( in );
}


bool match_double ( double d1, double d2 )
{
    if ( isnan(d1) || isnan(d2) )
    {
        return false;
    }
    if ( fabs( d1 - d2 ) > epsilon )
    {
        return false;
    }

    return true;
}


uint64_t
compare_solutions ( double *solution, double *other_solution, int64_t N )
{
    uint64_t error_count = 0;

    for ( int64_t i=0; i<N; i++ )
    {
        if ( !match_double ( solution[i], other_solution[i] ) )
        {
		printf("%lf != %lf, %ld\n", solution[i], other_solution[i], i);
            error_count++;
        }
    }

    return error_count;
}

