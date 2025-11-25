# Procedure to calculate the AT values for each node in a graph
# adjMat - adjacency matrix of the graph
# wMat - weight matrix of the graph
# nodes - list of nodes in the graph, each node represented as a list [id AT RAT SLACK]
proc calcAT {adjMat wMat nodes} {
    set numNodes [llength $nodes]
    # Initialize the arrival times with 0 for all nodes
    set arrivalTimes [lrepeat $numNodes 0]
    
    # Create the adjacency matrix array
    # Create the adjacency matrix array
    array set adjMatArr {}
    for {set i 0} {$i < $numNodes} {incr i} {
        set adjList {}
        for {set j 0} {$j < $i} {incr j} {
            if {[lindex $adjMat $j $i] == 1} {
                lappend adjList $j
            }
        }
    set adjMatArr($i) $adjList
    }
    
    # Iterate over the nodes list to calculate arrival times
    foreach node $nodes {
        set index [lindex $node 0]
        set at [lindex $node 1]
        set rat [lindex $node 2]
        set slack [lindex $node 3]
        
        # Find the connected nodes for the current node
        set connectedNodes $adjMatArr($index)
        # Calculate the maximum arrival time among the connected nodes
        set maxArrivalTime 0
        foreach connectedNode $connectedNodes {
            set weight [lindex $wMat $connectedNode $index]
            set connectedAt [lindex $arrivalTimes $connectedNode]
            set arrivalTime [expr {$connectedAt + $weight}]
            if {$arrivalTime > $maxArrivalTime} {
                set maxArrivalTime $arrivalTime
            }
        }

        #puts "maxArrivalTime: $maxArrivalTime"
        # Update the arrival time for the current node
        if {$maxArrivalTime > $at} {
            set at $maxArrivalTime
        }
        
        # Update the arrival time for the current node in arrivalTimes
        lset arrivalTimes $index $at
        
        # Update the nodesList with the updated AT value
        set updatedNode [list $index $at $rat $slack]
        lset nodes $index $updatedNode
    }
    return $nodes
}


# Procedure to calculate the RAT values for each node in a graph
# adjMat - adjacency matrix of the graph
# wMat - weight matrix of the graph
# nodes - list of nodes in the graph, each node represented as a list [id AT RAT SLACK]
proc calcRAT {adjMat wMat nodes T} {
    set numNodes [llength $nodes]
    # Initialize the required arrival times with a specific value (T) for all nodes
    set ratValues [lrepeat $numNodes $T]
    # Create the adjacency matrix array
    array set adjMatArr {}
    for {set i $numNodes} {$i >= 0} {incr i -1} {
        set adjList {}
        for {set j $i} {$j < $numNodes} {incr j } {
            if {[lindex $adjMat $i $j] == 1} {
                lappend adjList $j
            }
        }
        set adjMatArr($i) $adjList
    }
    
    # Iterate over the nodes list to calculate required arrival times
    foreach node [lreverse $nodes] {
        set index [lindex $node 0]
        set at [lindex $node 1]
        set rat [lindex $node 2]
        set slack [lindex $node 3]
        set rat $T
        # Find the connected nodes for the current node
        set connectedNodes $adjMatArr($index)
        
        # Calculate the minimum required arrival time among the connected nodes
        set minRAT $T
        foreach connectedNode $connectedNodes {
            set weight [lindex $wMat $index $connectedNode]
            set connectedRAT [lindex $ratValues $connectedNode]
            set requiredArrivalTime [expr {$connectedRAT - $weight}]
            if {$requiredArrivalTime < $minRAT} {
                set minRAT $requiredArrivalTime
            }
        }
        
        # Update the required arrival time for the current node
        if {$minRAT < $rat} {
            set rat $minRAT
        }
        
        # Update the required arrival time for the current node in ratValues
        lset ratValues $index $rat
        
        # Update the nodesList with the updated RAT value
        set updatedNode [list $index $at $rat $slack]
        lset nodes $index $updatedNode
    }
    return $nodes
}


# Procedure to calculate the SLACK values for each node in a graph
# adjMat - adjacency matrix of the graph
# wMat - weight matrix of the graph
# nodes - list of nodes in the graph, each node represented as a list [id AT RAT SLACK]
proc calcSlack {adjMat wMat nodes T} {

    # Calculate the AT values
    set updatedNodes [calcAT $adjMat $wMat $nodes]
    
    # Calculate the RAT values
    set updatedNodes [calcRAT $adjMat $wMat $updatedNodes $T]
    
 # Iterate over the nodes to calculate the slack values
    foreach node $updatedNodes {
        set index [lindex $node 0]
        set at [lindex $node 1]
        set rat [lindex $node 2]
        set slack [lindex $node 3]
        
        set nodeSlack [expr {$rat - $at}]
        
        # Update the slack value for the current node
        set updatedNode [list $index $at $rat $nodeSlack]
        lset updatedNodes $index $updatedNode
        lset nodes $index $updatedNode
    }
    
    # Check for nodes with negative slack
    set nodesWithNegativeSlack {}
    foreach node $updatedNodes {
        set index [lindex $node 0]
        set slack [lindex $node 3]
        
        if {$slack < 0} {
            lappend nodesWithNegativeSlack "Node $index has negative slack: $slack"
        }
    }
    
    # Print nodes with negative slack
    if {[llength $nodesWithNegativeSlack] > 0} {
        puts "Nodes with negative slack:"
        puts [join $nodesWithNegativeSlack "\n"]
    }
    
    return $nodes
}


# Define a function to initialize a queue
proc init_queue {qvar} {
  upvar 1 $qvar Q
  set Q [list]
}

# Define a function to add an element to a queue
proc enqueue {qvar elem} {
  upvar 1 $qvar Q
  lappend Q $elem
}

# Define a function to remove an element from a queue
proc dequeue {qvar} {
  upvar 1 $qvar Q
  set head [lindex $Q 0]
  set Q [lrange $Q 1 end]
  return $head
}

# Define a function to check if a queue is empty
proc is_empty {qvar} {
  upvar 1 $qvar Q
  return [expr {[llength $Q] == 0}]
}

proc topologicalSort {nodes adjMat} {

  # Create an empty list to hold the sorted nodes
  set sortedList {}
  # Compute the indegree of each node
  array set indegrees {}
  for {set i 0} {$i < [llength $nodes]} {incr i} {
    set indegrees([lindex $nodes $i 0]) 0
  }
  for {set i 0} {$i < [llength $nodes]} {incr i} {
    set currentIndex [lindex [lindex $nodes $i] 0]
    for {set j 0} {$j < [llength $adjMat]} {incr j} {
        if {[lindex $adjMat $j $currentIndex] == 1} {
          incr indegrees([lindex $nodes $i 0])
      }
    }
  }

  # Create a queue and add all nodes with indegree 0
  init_queue Q
  for {set i 0} {$i < [llength $nodes]} {incr i} {
    if {$indegrees([lindex $nodes $i 0]) == 0} {
      enqueue Q [lindex $nodes $i]
    }
  }

  # Visit all nodes in the queue
  while {! [is_empty Q]} {
    set currentNode [dequeue Q]
    set currentIndex [lindex $currentNode 0]
    lappend sortedList $currentNode
    for {set i 0} {$i < [llength $adjMat]} {incr i} {
      if {[lindex $adjMat $currentIndex $i] == 1} {
        incr indegrees([lindex $nodes $i 0]) -1
        if {$indegrees([lindex $nodes $i 0]) == 0} {
          enqueue Q [lindex $nodes $i]
        }
      }
    }
  }
   #Check if a cycle exists
  if {[llength $sortedList] != [llength $nodes]} {
    return "Error: Graph contains a cycle"
  }
  return $sortedList
}

set result [calcSlack $adjacencyMatrix $weightsMatrix $nodesList 12]
