Scriptname slaScanAllScript extends Quest  

ReferenceAlias Property SLActor01 Auto
ReferenceAlias Property SLActor02 Auto
ReferenceAlias Property SLActor03 Auto
ReferenceAlias Property SLActor04 Auto
ReferenceAlias Property SLActor05 Auto
ReferenceAlias Property SLActor06 Auto
ReferenceAlias Property SLActor07 Auto
ReferenceAlias Property SLActor08 Auto
ReferenceAlias Property SLActor09 Auto
ReferenceAlias Property SLActor10 Auto
ReferenceAlias Property SLActor11 Auto
ReferenceAlias Property SLActor12 Auto
ReferenceAlias Property SLActor13 Auto
ReferenceAlias Property SLActor14 Auto
ReferenceAlias Property SLActor15 Auto
ReferenceAlias Property SLActor16 Auto
ReferenceAlias Property SLActor17 Auto
ReferenceAlias Property SLActor18 Auto
ReferenceAlias Property SLActor19 Auto
ReferenceAlias Property SLActor20 Auto
ReferenceAlias Property SLActor21 Auto
ReferenceAlias Property SLActor22 Auto
ReferenceAlias Property SLActor23 Auto
ReferenceAlias Property SLActor24 Auto
ReferenceAlias Property SLActor25 Auto

ReferenceAlias[] Property arousedAliases Auto

Actor [] Property arousedActors Auto Hidden


Int Function GetArousedActors()
	
	Start()

	Utility.wait(0.3)

	Int actorCount = 0
	arousedActors = new Actor[25]
    
    Int ii = 0
    While ii < 25
        
        Actor aroused = arousedAliases[ii].GetActorRef()
        If aroused
            arousedActors[actorCount] = aroused
            actorCount += 1
        EndIf
        
        ii += 1
        
    EndWhile
	
	Stop()
	
	Reset()
	
	Return actorCount
    
EndFunction


Function DebugTraceActors()

	Debug.Trace("Actor  1 " + SLActor01.getReference())
	Debug.Trace("Actor  2 " + SLActor02.getReference())
	Debug.Trace("Actor  3 " + SLActor03.getReference())
	Debug.Trace("Actor  4 " + SLActor04.getReference())
	Debug.Trace("Actor  5 " + SLActor05.getReference())
	Debug.Trace("Actor  6 " + SLActor06.getReference())
	Debug.Trace("Actor  7 " + SLActor07.getReference())
	Debug.Trace("Actor  8 " + SLActor08.getReference())
	Debug.Trace("Actor  9 " + SLActor09.getReference())
	Debug.Trace("Actor 10 " + SLActor10.getReference())
	Debug.Trace("Actor 11 " + SLActor11.getReference())
	Debug.Trace("Actor 12 " + SLActor12.getReference())
	Debug.Trace("Actor 13 " + SLActor13.getReference())
	Debug.Trace("Actor 14 " + SLActor14.getReference())
	Debug.Trace("Actor 15 " + SLActor15.getReference())
	Debug.Trace("Actor 16 " + SLActor16.getReference())
	Debug.Trace("Actor 17 " + SLActor17.getReference())
	Debug.Trace("Actor 18 " + SLActor18.getReference())
	Debug.Trace("Actor 19 " + SLActor19.getReference())
	Debug.Trace("Actor 20 " + SLActor20.getReference())
	Debug.Trace("Actor 21 " + SLActor21.getReference())
	Debug.Trace("Actor 22 " + SLActor22.getReference())
	Debug.Trace("Actor 23 " + SLActor23.getReference())
	Debug.Trace("Actor 24 " + SLActor24.getReference())
	Debug.Trace("Actor 25 " + SLActor25.getReference())
	
EndFunction
