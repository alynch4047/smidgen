
import std.stdio: writeln;
import core.memory: GC;
import std.random: Mt19937;

import morselcore.WrappedObject: getNumWrappedObjects;

import morselcore.Rect;
import morselcore.Point;


/**
* Clear all registers etc. to try and flush references before doing a GC.collect()
*/
void spinWheels() {
	Mt19937 gen;
	uint a = gen.front;
	uint b;
	uint c;
	uint d;
	if (a > 1e3) {
		gen.popFront;
		b = gen.front;
		if (b < 1e3) {
			gen.popFront;
			c = gen.front;
		}
	} 
	
}


void gcCollect() {
	spinWheels();
	GC.collect();
}

void createOneRect() {
	auto rect1 = new Rect(5, 5);
	writeln(rect1.area());
	assert(getNumWrappedObjects() == 1);
}


int main() {
	assert(getNumWrappedObjects() == 0);
	createOneRect();
	gcCollect();
//	assert(getNumWrappedObjects() == 0);
	
	foreach(i; 0 .. 10) {
		foreach(j; 0 .. 10) {
			Rect rect = new Rect(1000, 1000);
		}
		writeln("iter ", i);
		gcCollect();
	}
	writeln("Num wrapped objects ", getNumWrappedObjects());
	
	return 0;
}	