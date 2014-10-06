# ==========================================================
# CREATE FARFIELD
# ==========================================================
# Creates spherical farfield for selected domains.
#
#

package require PWI_Glyph

set farfieldRadius  20
set farfieldSpacing  2
set freestreamAxis   X

set dim [pw::Application getCAESolverDimension]
if {$dim == 2} {
    puts "Only works in 3D."
    exit
}

proc ComputeExtents {doms} {

    foreach dom $ents(Domains) {

        set domExtents [$dom getExtents]

        set min [pwu::Vector3 minimum [lindex $domExtents 0] [lindex $domExtents 1]]
        set max [pwu::Vector3 maximum [lindex $domExtents 0] [lindex $domExtents 1]]

        if {![info exists absMin]} {
            set absMin $min
        }

        if {![info exists absMax]} {
            set absMax $max
        }

        set absMin [pwu::Vector3 minimum $min $absMin]
        set absMax [pwu::Vector3 maximum $max $absMax]

        set extents [list $absMin $absMax]

    }   

    return $extents

}

proc ComputeLargestExtent {extents} {

    set dX [expr {[lindex $absMax 0]-[lindex $absMin 0]}]
    set dY [expr {[lindex $absMax 1]-[lindex $absMin 1]}]
    set dZ [expr {[lindex $absMax 2]-[lindex $absMin 2]}]

    set largest [lindex [lsort -decreasing $dX $dY $dZ"] 0]

    return $largest

}

proc ComputeCenter {extents} {

    set centerX [expr {([lindex $extents 1 0]+[lindex $extents 0 0])/2.0}]
    set centerY [expr {([lindex $extents 1 1]+[lindex $extents 0 1])/2.0}]
    set centerZ [expr {([lindex $extents 1 2]+[lindex $extents 0 2])/2.0}]

    return [list $centerX $centerY $centerZ]

}

proc CreateSymmetryDomain {} {

    set symMode [pw::Application begin Create]

        set symDom [pw::DomainUnstructured create]

            set extEdge [pw::Edge createFromConnectors $ffSymCons]
            $symDom addEdge $extEdge
            set intEdge [pw::Edge createFromConnectors $inSymCons]
            $symDom addEdge $intEdge

        if {[$symDom getCellCount] == "0"} {
            $intEdge reverse
        }

    $symMode end
    unset symMode

}

proc CreateFarfield { scaledRadius center axis angle scaledSpacing extents} {

    set radius  [expr {$scaledRadius * $extents}]
    set spacing [expr {$scaledSpacing * $extents}]

    set dZ  [expr {[lindex $center 2] - $radius}]
    set cp1 [list [lindex $center 0] [lindex $center 1] $dZ]
    set dZ  [expr {[lindex $center 2] + $radius}]
    set cp2 [list [lindex $center 0] [lindex $center 1] $dZ]

    set circSeg [pw::SegmentCircle create]
        $circSeg addPoint $cp1
        $circSeg addPoint $cp2
        $circSeg setCenterPoint $center "0.0 1.0 0.0"
   
    set circCrv [pw::Curve create]
        $circCrv addSegment $circSeg
        $circCrv setName "outer-circle"

    set hemiSphere [pw::Surface create]
        $hemiSphere revolve -angle 180 $circCrv $cp1 "0.0 0.0 -1.0"
        $hemiSphere setName "outer-sphere"

    pw::Connector setCalculateDimensionSpacing $spacing
    set hemiDoms [pw::DomainUnstructured createOnDatabase [list $hemiSphere]]

    for {set i 0} {$i < [llength $hemiDoms]} {incr i} {
        
        set dom [lindex $hemiDoms $i]
        $dom setRenderAttribute LineMode "Boundary"
        set edge [$dom getEdge 1]
      
        for {set j 1} {$j <= [$edge getConnectorCount]} {incr j} {
            lappend hemiCons($i) [$edge getConnector $j]
        }
   
    }

    set symCons [Subtraction $hemiCons(0) $hemiCons(1)]

    return [list $hemiDoms $symCons]

}

proc CreateSphere {scaledRadius center axis scaledSpacing extents} {

    return [CreateFarfield $scaledRadius $center $axis 360 $scaledSpacing $extents]

}

proc CreateHemisphere {scaledRadius center axis scaledSpacing extents} {

    return [CreateFarfield $scaledRadius $center $axis 180 $scaledSpacing $extents]

}

proc GetFreeConnectors {cons} {

    set freeCons {}

    foreach con $cons {

        set testFree [llength [pw::Domain getDomainsFromConnectors $con]]
        if {$testFree == 1} {
            lappend freeCons $con
        }

    }

    return $freeCons

}

proc GetConsFromDoms {doms}  {

    set cons {}

    foreach dom $doms {

        set numEdges [$dom getEdgeCount]

        for {set i 1} {$i <= $numEdges} {incr i} {

            set edge    [$dom getEdge $i]
            set numCons [$edge getConnectorCount]

            for {set j 1} {$j <= $numCons} {incr j} {

                lappend cons [$edge getConnector $j]

            }

        }

    }

    return $cons

}

set mask [pw::Display createSelectionMask -requireDomain {}]
pw::Display getSelectedEntities -selectionmask $mask ents

if {![llength $ents(Domains)]} {
    pw::Display selectEntities -description "Pick domains." -selectionmask $mask ents
}

set conList      [GetConsFromDoms $ents(Domains)]
set symmetryCons [GetFreeConnectors $conList]

if {[llength $symmetryCons]} {

    puts "Symmetric case."

    



} else {

    puts "Full grid."

    


}





#pw::Display setSelectedEntities $block
