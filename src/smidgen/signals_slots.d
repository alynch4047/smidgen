
module smidgen.signals_slots;

import std.stdio: writeln;
import std.conv;
import std.string: format;
import std.traits;
import std.variant;
import std.array: join;
import std.algorithm: find;
import std.string;


class SlotException: Exception {
    this(string message) {
        super(message);
    }
}


class SignalSlotConnection {
	
	string signal; 
	QObjectSS receiver;
	string slot;
	
	this(string signal, QObjectSS receiver, string slot) {
		this.signal = signal;
		this.receiver = receiver;
		this.slot = slot;
	}
	
	override string toString() {
		return "<SignalSlotConnection %s %s %s>".format(signal, receiver, slot);
	}
}

/**
* This class contains the necessary code to manage the setting up and tearing down of
* connections, and to handle the emits of signals and activates of slot methods.
*/ 
class QObjectSS {
	
    SignalSlotConnection[] connections;
    /// All the objects that have connections with this as the receiver
    QObjectSS[] connectedFrom;
    
    ~this() {
    	tidyUpConnections();
    }
    
    /**
    * Delete any connections to or from this object
    */ 
    void tidyUpConnections() {
    	foreach(sender; connectedFrom) {
    		sender.removeConnectionsToReceiver(this);
    	}
    	connections = null;
    }
    
    /**
    * Remove all connections to the given receiver
    */
    void removeConnectionsToReceiver(QObjectSS receiver) {
    	SignalSlotConnection[] newConnections;
    	foreach(connection; connections) {
    		if(connection.receiver !is receiver) {
    			newConnections ~= connection;
    		}
    	}
    	connections = newConnections;
    }
    
    /**
    * Take note that a connection to this object has been from sender
    */
    void noteConnectionFrom(QObjectSS sender) {
    	connectedFrom ~= sender;
    }
    
    bool nativeConnect(QObjectSS sender, string signal, QObjectSS receiver, string slot) {
    	return false;
    }
    
    final bool doNativeConnect(QObjectSS sender, string signal, QObjectSS receiver, string slot) {
    	auto signalName = QSIGNAL(signal);
    	auto slotName = QSLOT(slot);
    	return nativeConnect(sender, signalName, receiver, slotName);
    }
    
    final void connect(QObjectSS sender, string signal, QObjectSS receiver, string slot) {
        bool success = doNativeConnect(sender, signal, receiver, slot);
        if (success) return;
        SignalSlotConnection connection = new SignalSlotConnection(signal, receiver, slot);
        receiver.noteConnectionFrom(sender);
        sender.connections ~= connection;
    }
    
    final void emit(string signalName, T...)(T args) {
        Variant[] variants;
        foreach(arg; args) {
            variants ~= Variant(arg);
        }
        foreach(connection; connections) {
        	if (connection.signal == signalName) {
        		connection.receiver.activate(connection.slot, variants);
        	}	
        }	
    }	
	
	bool activate(string slotName, Variant[] args) {
		string message = "%s could not run slot %s with args %s".format(this, slotName, args);
        throw new SlotException(message);
	}
}


/**
* Construct the switch statement that switches on the slotName to call the correct
* slot method. If no slot method is called then delegate up the class hierarchy.
*/
string getSwitch(Meta[] metas) {
	string template_ = """
	bool slotRun = false;
	switch(slotName) {
		%s
		default: break;
	}
	if (slotRun) {
        return true;
    } else {
        return super.activate(slotName, args);
    }   
""";
	string caseStatements = getCaseStatements(metas);
	return template_.format(caseStatements);
}

/**
* Call the slot method. The arguments are Variants so call the correct get! method
* on each argument passing the argument type.
*/
string makeRunStatement(Meta meta) {
	string template_ = """%s(%s);""";
	string[] argumentList;
	foreach(i, argType; meta.argTypes) {
		argumentList ~= "args[%s].get!(%s)".format(i, argType);
	}
	string arguments = argumentList.join(", ");
	return template_.format(meta.methodName, arguments);
}

/**
* Return the case statements that attempt to call the appropriate slot if its name
* matches the slotname. The arguments are Variants so call the correct get method
* on each argument passing the argument type.
*/ 
string getCaseStatements(Meta[] metas) {
	string caseStatements;
	foreach(meta; metas) {
		string template_ = """
		case(\"%s\"):
			//writeln(\"RunB \" ~ %s);
			try {
				%s
				slotRun = true;
			} catch (VariantException) {
            // argument types did not match
			}
			break;
""";
	caseStatements ~= template_.format
		(meta.methodName, '"' ~ meta.methodName ~ '"', makeRunStatement(meta));
	}
	return caseStatements;
}


class Meta {
	string methodName;
	string[] argTypes;
}


/**
* Get the method names and argument types for each method
*/
Meta[] getMeta(T)() {
	Meta[] metas;
	foreach (memberS; __traits(allMembers, T)) {
		static if (__traits(isVirtualMethod, __traits(getMember, T, memberS))) {
			auto meta = new Meta();
			metas ~= meta;
			meta.methodName = memberS;
			foreach(i, paramType; ParameterTypeTuple!(__traits(getMember, T, memberS))) {
				meta.argTypes ~= paramType.stringof;
			}
		}
	}
	return metas;	
}

/**
* QOBJECT is CTFE code that captures the names of class methods and their parameter types,
* and stores them in a data structure meta. The meta data structure is used
* by activate() to marshal the `emit!`ted call to the correct method with the correct
* parameters. 
*/
string QOBJECT() {
		return	`
		override bool activate(string slotName, Variant[] args) {
			//writeln("activate ", slotName);
			mixin(getSwitch(getMeta!(typeof(this))()));
		}	`;
}

string QSIGNAL(string signal) {
	return "2" ~ signal;
}

string QSLOT(string slot) {
	return "1" ~ slot;
}

