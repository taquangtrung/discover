/*
 * Migrated to Discover: Ta Quang Trung
 * Date: October 28, 2020
 */

#include "discover.h"
#include <deque>

using namespace std;

int global_obj;
int *global_ptr = &global_obj;

class A {
  public:
    virtual void f(int *i) const {
      __assert_must_alias(global_ptr, i);
    }
};

int main(int argc, char **argv)
{
  int *ptr = &global_obj;

  deque<A> adeque;
  A a;
  adeque.push_back(a);

  const A *aptr = &adeque.front();

  aptr->f(ptr);

  return 0;
}