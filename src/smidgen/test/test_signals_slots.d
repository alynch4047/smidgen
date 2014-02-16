/**
*
* Authors: A Lynch, alynch4047@gmail.com
* Copyright: A Lynch, 2013
* License: GPL v2
*/
module smidgen.test.test_signals_slots;

import unit_threaded.all;

import std.stdio: writeln;
import std.conv: to;
import std.string: format;
import std.variant: Variant, VariantException, VariantN;
import std.array: join;
import std.algorithm: find;

import smidgen.signals_slots;


class Y {
	
	int y;
	
	this(int y) {
		this.y = y;
	}
	
}


class Z {
	
	int z;
	
	this(int z) {
		this.z = z;
	}	
	
}


class Bar: QObjectSS {
	
	int val;
	
	mixin(QOBJECT());
	
	void doBar(Y y1, Y y2) {
		val = y1.y + 2 * y2.y;
	}
	
}


class Foo: QObjectSS {
	
	int val;
	
	mixin(QOBJECT());
	
	void doFoo(Z z, Y y) {
		val = z.z + 10 * y.y;
	}
}

void testConnectAndEmit() {
	Foo f = new Foo();
	Bar b = new Bar();
	Bar b2 = new Bar();
	
	f.connect(f, "e1", b, "doBar");
	b2.connect(b2, "e2", f, "doFoo");
	
	f.emit!"e1"(new Y(3), new Y(5));
	checkEqual(b.val, 13);
	
	b2.emit!"e2"(new Z(7), new Y(9));
	checkEqual(f.val, 97);
	
}

void testConnectAndEmitWithInvalidParameters() {
	
	Foo f = new Foo();
	Foo g = new Foo();
	
	g.connect(g, "e1", f, "doBar");
	
	try {
		g.emit!"e1"(new Y(1), 2);
		throw new Exception("Shouldn't get here");
	} catch (SlotException) {
		// pass
	}	
}

void testConnectDeleteReceiverAndEmit() {
	
	Foo f = new Foo();
	Foo g = new Foo();
	
	g.connect(g, "e1", f, "doBar");
	g.connect(g, "e2", f, "getZSize");
	
	writeln(f.connectedFrom);
	
	f.destroy();
	
	g.emit!"e1"(new Y(1), new Y(2));
	g.emit!"e2"(new Z(3), new Y(4));	
}
