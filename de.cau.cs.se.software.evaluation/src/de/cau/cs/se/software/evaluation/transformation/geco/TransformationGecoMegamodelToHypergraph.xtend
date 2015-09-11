package de.cau.cs.se.software.evaluation.transformation.geco

import de.cau.cs.se.software.evaluation.transformation.AbstractTransformation
import de.cau.cs.se.geco.architecture.architecture.Model
import de.cau.cs.se.software.evaluation.hypergraph.Hypergraph
import org.eclipse.core.runtime.IProgressMonitor
import de.cau.cs.se.software.evaluation.hypergraph.HypergraphFactory
import java.util.Map
import de.cau.cs.se.geco.architecture.architecture.Metamodel
import de.cau.cs.se.software.evaluation.hypergraph.Node
import java.util.HashMap
import de.cau.cs.se.geco.architecture.architecture.Weaver
import de.cau.cs.se.geco.architecture.architecture.Generator
import org.eclipse.xtext.common.types.JvmGenericType

import static extension de.cau.cs.se.geco.architecture.typing.ArchitectureTyping.*
import static extension de.cau.cs.se.software.evaluation.transformation.HypergraphCreationHelper.*

/**
 * Transform geco model to a hypergraph.
 */
class TransformationGecoMegamodelToHypergraph extends AbstractTransformation<Model, Hypergraph> {
	
	new(IProgressMonitor monitor) {
		super(monitor)
	}
	
	override transform(Model input) {
		result = HypergraphFactory.eINSTANCE.createHypergraph
		val Map<Metamodel, Node> mmNodeMap = new HashMap<Metamodel, Node>()
		
		input.metamodels.forEach[mm | 
			mm.metamodels.forEach[
				mmNodeMap.put(it, result.createNode(it.name, it))
			]
		]
		input.processors.forEach[p | 
			switch (p) {
				Weaver: {
					val weaverNode = result.createNode(p.reference.simpleName, p)
					val baseModelNode = mmNodeMap.get(p.resolveWeaverSourceModel.reference)
					
					result.createEdge(weaverNode, baseModelNode, weaverNode.name + "::" + baseModelNode.name, null)
					
					if (p.aspectModel instanceof Generator) {
						val generator = p.aspectModel as Generator
						val aspectModelNode = if (generator.reference instanceof JvmGenericType) {
							val aspectModelType = (generator.reference as JvmGenericType).determineGeneratorOutputType
							result.createNode("anonymous model " + aspectModelType.simpleName, aspectModelType)
						} else {
							result.createNode("anonymous model " + "type unknown", generator.reference)
						}
						val generatorNode = result.createNode(generator.reference.simpleName, p.aspectModel)
						val sourceModelNode = mmNodeMap.get(generator.sourceModel.reference)
						
						result.createEdge(generatorNode, sourceModelNode, generatorNode.name + "::" + sourceModelNode.name, null)
						result.createEdge(generatorNode, aspectModelNode, generatorNode.name + "::" + aspectModelNode.name, null)
						result.createEdge(weaverNode, aspectModelNode, weaverNode.name + "::" + aspectModelNode.name, null)
					} else {
						 val aspectModelNode = mmNodeMap.get(p.aspectModel as Metamodel)
						 result.createEdge(weaverNode, aspectModelNode, weaverNode.name + "::" + aspectModelNode.name, null)
					}
				}
				Generator: {
					val generatorNode = result.createNode(p.reference.simpleName, p)
					if (p.sourceModel.reference != null) {
						val sourceModelNode = mmNodeMap.get(p.sourceModel.reference)
						result.createEdge(generatorNode, sourceModelNode, generatorNode.name + "::" + sourceModelNode.name, null)
					}
					
					val targetModelNode = mmNodeMap.get(p.targetModel.reference)
					result.createEdge(generatorNode, targetModelNode, generatorNode.name + "::" + targetModelNode.name, null)
				}
			}
		]
		
		return result
	}
		
}