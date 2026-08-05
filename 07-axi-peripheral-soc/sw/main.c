#include "ap/CommTest/CommTest.h"

int main() {

	CommTest_Init();

	while (1) {
		CommTest_Execute();
	}

	return 0;
}
