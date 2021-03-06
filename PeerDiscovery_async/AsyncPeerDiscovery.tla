---------- MODULE AsyncPeerDiscovery ----------

EXTENDS FiniteSets, Naturals

CONSTANT NODES \* set of all node IDs

VARIABLES
    dns_request_enabled, \* tuple of each node's DNS flag
    dns_requests,        \* set of node IDs who are waiting for peers from DNS
    peers                \* tuple of each node's peer set

vars == <<dns_request_enabled, dns_requests, peers>>

ASSUME NODES \subseteq Nat
ASSUME Cardinality(NODES) > 3

(***********)
(* Actions *)
(***********)

\* a node who has not requested peers from the DNS, requests peers from the DNS
DNS_request == \E n \in NODES :
    /\ dns_request_enabled[n]
    /\ n \notin dns_requests
    /\ dns_requests' = dns_requests \cup {n}
    /\ UNCHANGED <<dns_request_enabled, peers>>

\* DNS responds to a node's request
DNS_response == \E n \in dns_requests :
    \E ns \in SUBSET (NODES \ {n}) :
        /\ Cardinality(ns) >= 2
        /\ dns_request_enabled' = [ dns_request_enabled EXCEPT ![n] = ~@ ]
        /\ dns_requests' = dns_requests \ {n}
        /\ peers' = [ peers EXCEPT ![n] = ns ]

(*****************)
(* Specification *)
(*****************)

Init ==
    /\ dns_request_enabled = [ n \in NODES |-> TRUE ]
    /\ dns_requests = {}
    /\ peers = [ n \in NODES |-> {} ]

Next == DNS_request \/ DNS_response

Fairness ==
    /\ WF_vars(DNS_request)
    /\ WF_vars(DNS_response)

Spec == Init /\ [][Next]_vars /\ Fairness

(***************************)
(* Invariants & Properties *)
(***************************)

TypeOK ==
    /\ \A n \in NODES : dns_request_enabled[n] \in BOOLEAN
    /\ dns_requests \subseteq NODES
    /\ \A n \in NODES : peers[n] \subseteq NODES

Safety == \A n \in NODES : n \notin peers[n]

Liveness ==
    /\ <>[](\A n \in NODES : dns_request_enabled[n] = FALSE)
    /\ <>[](\A n \in NODES : Cardinality(peers[n]) >= 2)
    /\ \A n \in NODES : n \in dns_requests ~> n \notin dns_requests

===============================================
