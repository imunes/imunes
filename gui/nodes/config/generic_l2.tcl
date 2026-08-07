addCase "updateNodeGUI" "label" {
	setNodeLabel $node_id $new_value
}

addCase "updateNodeGUI" "canvas" {
	setNodeCanvas $node_id $new_value
}

addCase "updateNodeGUI" "iconcoords" {
	setNodeCoords $node_id $new_value
}

addCase "updateNodeGUI" "labelcoords" {
	setNodeLabelCoords $node_id $new_value
}

addCase "updateNodeGUI" "custom_icon" {
	setNodeCustomIcon $node_id $new_value
}
