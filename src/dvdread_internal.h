#ifndef LIBDVDREAD_DVDREAD_INTERNAL_H
#define LIBDVDREAD_DVDREAD_INTERNAL_H

#ifdef _MSC_VER
#include <unistd.h>
#endif /* _MSC_VER */

#define CHECK_VALUE(arg) \
 if(!(arg)) { \
   fprintf(stderr, "\n*** libdvdread: CHECK_VALUE failed in %s:%i ***" \
                   "\n*** for %s ***\n\n", \
                   __FILE__, __LINE__, # arg ); \
 }

#endif /* LIBDVDREAD_DVDREAD_INTERNAL_H */
