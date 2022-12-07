// ---------------------------------------------------------
// TDT4200 Parallel Computing - Graded CUDA
// ---------------------------------------------------------
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <math.h>
#include <cooperative_groups.h>

namespace cg = cooperative_groups;

#include "../inc/argument_utils.h"


typedef int64_t int_t;
typedef double real_t;

int_t
    N,
    max_iteration,
    snapshot_frequency;

const real_t
    domain_size = 10.0,
    gravity = 9.81,
    density = 997.0;

real_t
    *h_mass_0 = NULL,
    *h_mass_1 = NULL,
    *d_mass_0 = NULL,
    *d_mass_1 = NULL,

    *h_mass_velocity_x_0 = NULL,
    *h_mass_velocity_x_1 = NULL,
    *d_mass_velocity_x_0 = NULL,
    *d_mass_velocity_x_1 = NULL,

    *h_mass_velocity_y_0 = NULL,
    *h_mass_velocity_y_1 = NULL,
    *d_mass_velocity_y_0 = NULL,
    *d_mass_velocity_y_1 = NULL,

    *h_mass_velocity = NULL,
    *d_mass_velocity = NULL,

    *h_velocity_x = NULL,
    *d_velocity_x = NULL,
    *h_velocity_y = NULL,
    *d_velocity_y = NULL,

    *h_acceleration_x = NULL,
    *d_acceleration_x = NULL,
    *h_acceleration_y = NULL,
    *d_acceleration_y = NULL,
    dx,
    dt;

#define PN(y,x)         mass_0[(y)*(N+2)+(x)]
#define PN_next(y,x)    mass_1[(y)*(N+2)+(x)]
#define PNU(y,x)        mass_velocity_x_0[(y)*(N+2)+(x)]
#define PNU_next(y,x)   mass_velocity_x_1[(y)*(N+2)+(x)]
#define PNV(y,x)        mass_velocity_y_0[(y)*(N+2)+(x)]
#define PNV_next(y,x)   mass_velocity_y_1[(y)*(N+2)+(x)]
#define PNUV(y,x)       mass_velocity[(y)*(N+2)+(x)]
#define U(y,x)          velocity_x[(y)*(N+2)+(x)]
#define V(y,x)          velocity_y[(y)*(N+2)+(x)]
#define DU(y,x)         acceleration_x[(y)*(N+2)+(x)]
#define DV(y,x)         acceleration_y[(y)*(N+2)+(x)]


#define cudaErrorCheck(ans) { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, const char *file, int line, bool abort=true)
{
    if (code != cudaSuccess) {
        fprintf(
            stderr,
            "GPUassert: \"%s | code: %d\"\n%s %d\n", 
            cudaGetErrorString(code), (int) code, file, line);
        if (abort) exit(code);
    }
}

__global__ void time_step( 
    real_t *velocity_x,
    real_t *velocity_y,
    real_t *acceleration_x, 
    real_t *acceleration_y,
    real_t *mass_velocity_x_0, 
    real_t *mass_velocity_x_1,
    real_t *mass_velocity_y_0, 
    real_t *mass_velocity_y_1,
    real_t *mass_velocity, 
    real_t *mass_0, 
    real_t *mass_1,
    real_t dx, 
    real_t dt,
    int_t N
 );


// TODO: Rewrite boundary_condition as a device function.
__device__ void 
boundary_condition ( real_t *domain_variable, int sign, int_t N );

void domain_init ( void );
void domain_save ( int_t iteration );
void domain_finalize ( void );

void *domain_save_threaded ( void *iter );

void
swap ( real_t** t1, real_t** t2 )
{
    real_t* tmp;
	tmp = *t1;
	*t1 = *t2;
	*t2 = tmp;
}


int
main ( int argc, char **argv )
{

    OPTIONS *options = parse_args( argc, argv );
    if ( !options )
    {
        fprintf( stderr, "Argument parsing failed\n" );
        exit(1);
    }

    N = options->N;
    max_iteration = options->max_iteration;
    snapshot_frequency = options->snapshot_frequency;

    domain_init();

    uint grid_size = (unsigned int) ceil((double)(N+2) / (double) 32.0);
    dim3 grid_layout = {grid_size, grid_size, 1};
    dim3 block_layout = {32, 32, 1};

    int elements = (N+2)*(N+2);

    for ( int_t iteration = 0; iteration <= max_iteration; iteration++ )
    {
        // TODO: Launch time_step kernels

        void * kernel_args[] = { 
            (void*) &d_velocity_x, 
            (void*) &d_velocity_y, 
            (void*) &d_acceleration_x,
            (void*) &d_acceleration_y,
            (void*) &d_mass_velocity_x_0,
            (void*) &d_mass_velocity_x_1,
            (void*) &d_mass_velocity_y_0,
            (void*) &d_mass_velocity_y_1,
            (void*) &d_mass_velocity,
            (void*) &d_mass_0,
            (void*) &d_mass_1,
            (void*) &dx,
            (void*) &dt,
            (void*) &N, 
        };

        // launch kernel in cooperative with appropriate args
        cudaErrorCheck(
            cudaLaunchCooperativeKernel(
                (void*) time_step,  
                grid_layout, 
                block_layout,
                kernel_args
            )
        );


        if ( iteration % snapshot_frequency == 0 )
        {
            printf (
                "Iteration %ld of %ld, (%.2lf%% complete)\n",
                iteration,
                max_iteration,
                100.0 * (real_t) iteration / (real_t) max_iteration
            );

            // TODO: Copy the masses from the device to host prior to domain_save
            cudaErrorCheck(cudaMemcpy(h_mass_0, d_mass_0, elements*sizeof(real_t), cudaMemcpyDeviceToHost));


            domain_save ( iteration );
        }

        // TODO: Swap device buffer pointers between iterations

        swap ( &d_mass_0, &d_mass_1 );
        swap ( &d_mass_velocity_x_0, &d_mass_velocity_x_1 );
        swap ( &d_mass_velocity_y_0, &d_mass_velocity_y_1 );
    }

    domain_finalize();

    exit ( EXIT_SUCCESS );
}

__global__ void
time_step( 
    real_t *velocity_x,
    real_t *velocity_y,
    real_t *acceleration_x, 
    real_t *acceleration_y,
    real_t *mass_velocity_x_0, 
    real_t *mass_velocity_x_1,
    real_t *mass_velocity_y_0, 
    real_t *mass_velocity_y_1,
    real_t *mass_velocity, 
    real_t *mass_0, 
    real_t *mass_1,
    real_t dx, 
    real_t dt,
    int_t N
)
{
    // TODO: Rewrite this function as one or more CUDA kernels
    // ---------------------------------------------------------
    // To ensure correct results, the participating threads in the thread
    // grid must be synchronized after calculating the accelerations (DU, DV).
    // If the grid is not synchronized, data dependencies cannot be guaranteed.


    cg::thread_group g = cg::this_thread();
    
    // time_step_1 

    boundary_condition ( mass_0, 1, N );
    boundary_condition ( mass_velocity_x_0, -1, N );
    boundary_condition ( mass_velocity_y_0, -1, N );

    int x = threadIdx.x + blockIdx.x * blockDim.x;
    int y = threadIdx.y + blockIdx.y * blockDim.y;


    if ((0 <= y && y <= N+1) && (0 <= x && x <= N+1)) {

        DU(y,x) = PN(y,x) * U(y,x) * U(y,x)
                + 0.5 * gravity * ( PN(y,x) * PN(y,x) / density );
        DV(y,x) = PN(y,x) * V(y,x) * V(y,x)
                + 0.5 * gravity * ( PN(y,x) * PN(y,x) / density );
    
    }

    cg::sync(g);

    // time_step_2    

    if ((1 <= y && y <= N) && (1 <= x && x <= N)) {

        U(y,x) = PNU(y,x) / PN(y,x);
        V(y,x) = PNV(y,x) / PN(y,x);

        PNUV(y,x) = PN(y,x) * U(y,x) * V(y,x);

        PNU_next(y,x) = 0.5*( PNU(y,x+1) + PNU(y,x-1) ) - dt*(
                        ( DU(y,x+1) - DU(y,x-1) ) / (2*dx)
                        + ( PNUV(y,x+1) - PNUV(y,x-1) ) / (2*dx));

        PNV_next(y,x) = 0.5*( PNV(y+1,x) + PNV(y-1,x) ) - dt*(
                        ( DV(y+1,x) - DV(y-1,x) ) / (2*dx)
                        + ( PNUV(y+1,x) - PNUV(y-1,x) ) / (2*dx));

        PN_next(y,x) = 0.25*( PN(y,x+1) + PN(y,x-1) + PN(y+1,x) + PN(y-1,x) ) - dt*(
                    ( PNU(y,x+1) - PNU(y,x-1) ) / (2*dx)
                    + ( PNV(y+1,x) - PNV(y-1,x) ) / (2*dx));
    }
}


// TODO: Rewrite boundary_condition as a device function.
__device__ void
boundary_condition ( real_t *domain_variable, int sign, int_t N )
{
    int x = threadIdx.x + blockIdx.x * blockDim.x;
    int y = threadIdx.y + blockIdx.y * blockDim.y;

    #define VAR(y,x) domain_variable[(y)*(N+2)+(x)]
    VAR(   0, 0   ) = sign*VAR(   2, 2   );
    VAR( N+1, 0   ) = sign*VAR( N-1, 2   );
    VAR(   0, N+1 ) = sign*VAR(   2, N-1 );
    VAR( N+1, N+1 ) = sign*VAR( N-1, N-1 );

    if (1 <= y && y <= N)  {
        VAR(   y, 0   ) = sign*VAR(   y, 2   );
        VAR(   y, N+1 ) = sign*VAR(   y, N-1 );
    }
    if (1 <= x && x <= N) {
        VAR(   0, x   ) = sign*VAR(   2, x   );
        VAR( N+1, x   ) = sign*VAR( N-1, x   );
    }
    #undef VAR
}


void
domain_init ( void )
{
    int elements = (N+2)*(N+2);

    // TODO: Allocate device buffers for masses, velocities and accelerations.
    // -----------------------------------------------------
    h_mass_0 = (real_t *) calloc ( elements, sizeof(real_t) );
    h_mass_1 = (real_t *) calloc ( elements, sizeof(real_t) );

    h_mass_velocity_x_0 = (real_t *) calloc ( elements, sizeof(real_t) );
    h_mass_velocity_x_1 = (real_t *) calloc ( elements, sizeof(real_t) );
    h_mass_velocity_y_0 = (real_t *) calloc ( elements, sizeof(real_t) );
    h_mass_velocity_y_1 = (real_t *) calloc ( elements, sizeof(real_t) );

    h_mass_velocity = (real_t *) calloc ( elements, sizeof(real_t) );

    h_velocity_x =  (real_t *) calloc ( elements, sizeof(real_t) );
    h_velocity_y = (real_t *) calloc ( elements, sizeof(real_t) );
    h_acceleration_x = (real_t *) calloc ( elements, sizeof(real_t) );
    h_acceleration_y = (real_t *) calloc ( elements, sizeof(real_t) );

    cudaErrorCheck(cudaMalloc(&d_mass_0, elements * sizeof(real_t)));
    cudaMalloc(&d_mass_1, elements * sizeof(real_t));

    cudaMalloc(&d_mass_velocity_x_0, elements * sizeof(real_t));
    cudaMalloc(&d_mass_velocity_x_1, elements * sizeof(real_t));
    cudaMalloc(&d_mass_velocity_y_0, elements * sizeof(real_t));
    cudaMalloc(&d_mass_velocity_y_1, elements * sizeof(real_t));

    cudaMalloc(&d_mass_velocity, elements * sizeof(real_t));

    cudaMalloc(&d_velocity_x, elements * sizeof(real_t));
    cudaMalloc(&d_velocity_y, elements * sizeof(real_t));

    cudaMalloc(&d_acceleration_x, elements * sizeof(real_t));
    cudaMalloc(&d_acceleration_y, elements * sizeof(real_t));



    for ( int_t y=1; y<=N; y++ )
    {
        for ( int_t x=1; x<=N; x++ )
        {
	    h_mass_0[y*(N+2) + x] = 1e-3;
	    h_mass_velocity_x_0[y*(N+2) + x] = 0.0;
	    h_mass_velocity_y_0[y*(N+2) + x] = 0.0;

            real_t cx = x-N/2;
            real_t cy = y-N/2;
            if ( sqrt ( cx*cx + cy*cy ) < N/20.0 )
            {
                h_mass_0[y*(N+2) + x] -= 5e-4*exp (
                    - 4*pow( cx, 2.0 ) / (real_t)(N)
                    - 4*pow( cy, 2.0 ) / (real_t)(N)
                );
            }

            h_mass_0[y*(N+2) + x] *= density;
        }
    }

    dx = domain_size / (real_t) N;
    dt = 5e-2;

    cudaMemcpy(d_mass_0           , h_mass_0           , elements * sizeof(real_t), cudaMemcpyHostToDevice );
    cudaMemcpy(d_mass_1           , h_mass_1           , elements * sizeof(real_t), cudaMemcpyHostToDevice );

    cudaMemcpy(d_mass_velocity_x_0, h_mass_velocity_x_0, elements * sizeof(real_t), cudaMemcpyHostToDevice );
    cudaMemcpy(d_mass_velocity_x_1, h_mass_velocity_x_1, elements * sizeof(real_t), cudaMemcpyHostToDevice );
    cudaMemcpy(d_mass_velocity_y_0, h_mass_velocity_y_0, elements * sizeof(real_t), cudaMemcpyHostToDevice );
    cudaMemcpy(d_mass_velocity_y_1, h_mass_velocity_y_1, elements * sizeof(real_t), cudaMemcpyHostToDevice );

    cudaMemcpy(d_mass_velocity    , h_mass_velocity    , elements * sizeof(real_t), cudaMemcpyHostToDevice );

    cudaMemcpy(d_velocity_x       , h_velocity_x       , elements * sizeof(real_t), cudaMemcpyHostToDevice );
    cudaMemcpy(d_velocity_y       , h_velocity_y       , elements * sizeof(real_t), cudaMemcpyHostToDevice );

    cudaMemcpy(d_acceleration_x   , h_acceleration_x   , elements * sizeof(real_t), cudaMemcpyHostToDevice );
    cudaMemcpy(d_acceleration_y   , h_acceleration_y   , elements * sizeof(real_t), cudaMemcpyHostToDevice );
}


void
domain_save ( int_t iteration )
{
    int_t index = iteration / snapshot_frequency;
    char filename[256];
    memset ( filename, 0, 256*sizeof(char) );
    sprintf ( filename, "data/%.5ld.bin", index );

    FILE *out = fopen ( filename, "wb" );
    if ( !out )
    {
        fprintf( stderr, "Failed to open file %s\n", filename );
        exit(1);
    }
    
    for ( int_t y = 1; y <= N; y++ )
    {
        fwrite ( &h_mass_0[y*(N+2)+1], N, sizeof(real_t), out );
    }
    fclose ( out );
}

void
domain_finalize ( void )
{
    free ( h_mass_0 );
    free ( h_mass_1 );
    free ( h_mass_velocity_x_0 );
    free ( h_mass_velocity_x_1 );
    free ( h_mass_velocity_y_0 );
    free ( h_mass_velocity_y_1 );
    free ( h_mass_velocity );
    free ( h_velocity_x );
    free ( h_velocity_y );
    free ( h_acceleration_x );
    free ( h_acceleration_y );

    // TODO: Free device arrays
    cudaFree(d_mass_0);
    cudaFree(d_mass_1);

    cudaFree(d_mass_velocity_x_0);
    cudaFree(d_mass_velocity_x_1);
    cudaFree(d_mass_velocity_y_0);
    cudaFree(d_mass_velocity_y_1);

    cudaFree(d_mass_velocity);

    cudaFree(d_velocity_x);
    cudaFree(d_velocity_y);
    
    cudaFree(d_acceleration_x);
    cudaFree(d_acceleration_y);

}
