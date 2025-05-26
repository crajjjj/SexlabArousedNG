Scriptname slaNakedScript extends Quest  

ReferenceAlias Property SLANaked1 Auto
ReferenceAlias Property SLANaked2 Auto
ReferenceAlias Property SLANaked3 Auto
ReferenceAlias Property SLANaked4 Auto
ReferenceAlias Property SLANaked5 Auto
ReferenceAlias Property SLANaked6 Auto
ReferenceAlias Property SLANaked7 Auto
ReferenceAlias Property SLANaked8 Auto

ReferenceAlias[] Property slaNakedNpcs Auto

Actor [] Property nakedActors Auto Hidden


Int Function GetNakedActors()
    
	Start()

	Utility.wait(0.3)

	Int nakedCount = 0
	nakedActors = new Actor[12]
    
    Int ii = 0
    While ii < 12
        
        Actor aroused = slaNakedNpcs[ii].GetActorRef()
        If aroused
            nakedActors[nakedCount] = aroused
            nakedCount += 1
        EndIf
        
        ii += 1
        
    EndWhile
	
	Stop()
	
	Reset()
	
	Return nakedCount
    
EndFunction
