'
'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"afuntype"
VERSION	"0.0001"
'
' #####  data types
'
TYPE DOG
  STRING*32  .name                      ' dog's name
  STRING*32  .hairColor                 ' dog's hair color
  FUNCADDR   .setName (DOG, STRING)     ' set the dog's name
END TYPE
'
' #####  functions
'
DECLARE  FUNCTION  Entry    ()
INTERNAL FUNCTION  NameDog  (DOG dog, name$)
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION  Entry ()
  DOG  dog
'
  PRINT
  PRINT
  dog.setName = &NameDog()
'
  answer$ = INLINE$ ("enter dog's name: ")
  @dog.setName (@dog, answer$)
'
  answer$ = INLINE$ ("enter dog's hair color: ")
  dog.hairColor = LEFT$ (answer$,32)
'
  PRINT "You claim "; dog.name; " has "; dog.hairColor; " hair."
END FUNCTION
'
'
' ########################
' #####  NameDog ()  #####
' ########################
'
FUNCTION  NameDog (DOG dog, answer$)

  answer$ = LEFT$ (answer$, 32)
  dog.name = answer$
END FUNCTION
END PROGRAM
