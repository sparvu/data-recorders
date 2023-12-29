-------------------------------- MODULE gcd --------------------------------

EXTENDS Integers

CONSTANTS A, B

VARIABLES x, y

Init == 
    /\ x = A
    /\ y = B

Next == 
    /\ x > y 
        /\ x' = x - y
        /\ y' = y
    \/ /\ y > x 
        /\ y' = y - x
        /\ x' = x
    \/ /\ x = y
        /\ UNCHANGED <<x, y>>

GCDInvariant == 
    x > 0 /\ y > 0

GCD == 
    x = y

=============================================================================
\* Modification History
\* Last modified Fri Dec 29 13:42:36 GMT 2023 by hp
\* Created Thu Dec 14 20:04:18 GMT 2023 by hp


