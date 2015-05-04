package de.cau.cs.se.evaluation.architecture.transformation.java

import de.cau.cs.se.evaluation.architecture.hypergraph.Edge
import de.cau.cs.se.evaluation.architecture.hypergraph.ModularHypergraph
import de.cau.cs.se.evaluation.architecture.hypergraph.Node
import java.util.List
import org.eclipse.jdt.core.dom.Assignment
import org.eclipse.jdt.core.dom.Block
import org.eclipse.jdt.core.dom.ClassInstanceCreation
import org.eclipse.jdt.core.dom.DoStatement
import org.eclipse.jdt.core.dom.EnhancedForStatement
import org.eclipse.jdt.core.dom.Expression
import org.eclipse.jdt.core.dom.FieldAccess
import org.eclipse.jdt.core.dom.ForStatement
import org.eclipse.jdt.core.dom.IMethodBinding
import org.eclipse.jdt.core.dom.ITypeBinding
import org.eclipse.jdt.core.dom.IfStatement
import org.eclipse.jdt.core.dom.InfixExpression
import org.eclipse.jdt.core.dom.LabeledStatement
import org.eclipse.jdt.core.dom.MethodDeclaration
import org.eclipse.jdt.core.dom.MethodInvocation
import org.eclipse.jdt.core.dom.NumberLiteral
import org.eclipse.jdt.core.dom.SimpleName
import org.eclipse.jdt.core.dom.Statement
import org.eclipse.jdt.core.dom.StringLiteral
import org.eclipse.jdt.core.dom.SwitchStatement
import org.eclipse.jdt.core.dom.SynchronizedStatement
import org.eclipse.jdt.core.dom.ThisExpression
import org.eclipse.jdt.core.dom.TryStatement
import org.eclipse.jdt.core.dom.TypeDeclaration
import org.eclipse.jdt.core.dom.VariableDeclaration
import org.eclipse.jdt.core.dom.VariableDeclarationFragment
import org.eclipse.jdt.core.dom.VariableDeclarationStatement
import org.eclipse.jdt.core.dom.WhileStatement

import static extension de.cau.cs.se.evaluation.architecture.transformation.NameResolutionHelper.*
import static extension de.cau.cs.se.evaluation.architecture.transformation.java.JavaASTEvaluation.*
import static extension de.cau.cs.se.evaluation.architecture.transformation.java.JavaHypergraphQueryHelper.*
import static extension de.cau.cs.se.evaluation.architecture.transformation.java.JavaHypergraphElementFactory.*

class JavaASTExpressionEvaluationHelper {
	
	/**
	 * Process an assignment expression.
	 */
	def static void processAssignment(Assignment assignment, ModularHypergraph graph, List<String> dataTypePatterns, Node node, 
		TypeDeclaration type, MethodDeclaration method
	) {
		val typeBinding = type.resolveBinding
		if (assignment.leftHandSide.isClassDataProperty(dataTypePatterns, typeBinding, method)) {
			/** Handle connections via a data edge. */
			val leftHandSide = assignment.leftHandSide
			switch(leftHandSide) {
				SimpleName: handleAssignmentSimpleNameEdgeResolving(assignment, graph, dataTypePatterns, typeBinding, node, type, method, leftHandSide)
				FieldAccess: {
					var prefix = leftHandSide.expression
					switch(prefix) {
						ThisExpression: handleAssignmentSimpleNameEdgeResolving(assignment, graph, dataTypePatterns, typeBinding, node, type, method, leftHandSide.name)
						default:
    						throw new UnsupportedOperationException("Left hand side of an assignment prefix expression type " + prefix.class + " is not supported by processAssignment")
					}
				}
				default:
    				throw new UnsupportedOperationException("Expression type " + leftHandSide.class + " is not supported by processAssignment")
			}
    	} else {
    		/** Handle call of methods and constructors via call edge. */
    		assignment.rightHandSide.composeCallEdgesForAssignmentRightHandSide(graph, dataTypePatterns, typeBinding, node, type, method)
    	}
    }
    
    /**
     * Create call edges for method and constructor calls found on the first level of the right hand side.
     * For nested expressions call the expression handler.
     */
    private static def void composeCallEdgesForAssignmentRightHandSide(Expression expression, ModularHypergraph graph, List<String> dataTypePatterns, 
   		ITypeBinding typeBinding, Node node, TypeDeclaration type, MethodDeclaration method
   	) {
   		switch(expression) {
   			MethodInvocation: {
   				expression.composeCallEdge(graph, dataTypePatterns, typeBinding, node, type, method)
   				expression.arguments.forEach[argument | (argument as Expression).evaluate(graph, dataTypePatterns, node, type, method)]
   			}
			InfixExpression: {
				expression.leftOperand.composeCallEdgesForAssignmentRightHandSide(graph, dataTypePatterns, typeBinding, node, type, method)
				expression.rightOperand?.composeCallEdgesForAssignmentRightHandSide(graph, dataTypePatterns, typeBinding, node, type, method)
			}
			ClassInstanceCreation: { 
				/** 
				 * data type value initialization => does not cause an edge referencing, 
				 * however check parameter for call edges.
				 */
				expression.arguments.forEach[argument | (argument as Expression).evaluate(graph, dataTypePatterns, node, type, method)]
			}
			NumberLiteral, SimpleName, StringLiteral: return
			default:
    			throw new UnsupportedOperationException("Expression type " + expression.class + " is not supported by assignNodesToEdge")
		}
   	}
   	
   	/**
   	 * Create an call edge between invocation method (target) and method (source) iff no such edge exists.
   	 */
   	private static def void composeCallEdge(MethodInvocation invocation, ModularHypergraph graph, 
   		List<String> dataTypePatterns, ITypeBinding typeBinding, Node node, TypeDeclaration type, MethodDeclaration method
   	) {
   		var edge = findCallEdge(graph.edges, method.resolveBinding, invocation.resolveMethodBinding)
   		if (edge == null) {
   			val targetNode = findNodeForMethodBinding(graph.nodes, invocation.resolveMethodBinding)
   			edge = createCallEdge(method.resolveBinding, invocation.resolveMethodBinding)
   			node.edges.add(edge)
   			targetNode.edges.add(edge)
   			graph.edges.add(edge)
   			System.out.println("composeCallEdge " + method.name + "--" + node.name + " " + targetNode.name + " " + edge.name)
   		}		
   	}
    	  
   	/**
   	 * Determine from a simple name to a data type and then reference 
   	 * the right hand side and the context method to that data edge.
   	 */
   	private static def void handleAssignmentSimpleNameEdgeResolving(Assignment assignment, ModularHypergraph graph, List<String> dataTypePatterns, 
   		ITypeBinding typeBinding, Node node, TypeDeclaration type, MethodDeclaration method, SimpleName leftHandSide
   	) {
   		val variableBinding = typeBinding.declaredFields.findFirst[it.name.equals(leftHandSide.fullyQualifiedName)]
		val edge = findDataEdge(graph.edges, variableBinding)
		if (edge == null) {
			throw new UnsupportedOperationException("Missing edge for " + variableBinding)
		} else {
			assignment.rightHandSide.assignNodesToEdge(graph, dataTypePatterns, node, type, method, edge)
			node.edges.add(edge) // TODO only add if unique
			System.out.println("handleAssignmentSimpleNameEdgeResolving <" + node.name + "> [" + edge.name + "]")
		}
   	}
    	    
    /**
     * Process a class instance creation in a local assignment. 
     */
    def static void processClassInstanceCreation(ClassInstanceCreation instanceCreation, ModularHypergraph graph, List<String> dataTypePatterns, Node node, TypeDeclaration clazz, MethodDeclaration method) {
    	val typeBinding = instanceCreation.resolveTypeBinding
    	val constructorBinding = instanceCreation.resolveConstructorBinding
    	if (typeBinding.isDataType(dataTypePatterns)) {
    		/** This is an instance creation of a data type and must be ignored. */
    		return
    	} else {
	    	/** create call edge as this is a local context. */
	    	val targetNode = graph.findOrCreateTargetNode(typeBinding, constructorBinding)
	    	
	    	val edge = createCallEdge(clazz, method, constructorBinding)
	    	graph.edges.add(edge)
	    	node.edges.add(edge)
	    	targetNode.edges.add(edge)
	    	System.out.println("processClassInstanceCreation <" + node.name + "> <" + targetNode.name + "> [" + edge.name + "]")
	    	
	    	/**
	    	 * node is the correct source node for evaluate, as all parameters are accessed inside of method and not the
	    	 * instantiated constructor.
	    	 */
	    	instanceCreation.arguments.forEach[argument | (argument as Expression).evaluate(graph, dataTypePatterns, node, clazz, method)]
	    }
    }
        
    /**
     * Process a method invocation in an expression. This might be a local method, an external method, or an data type method.
     */
    def static void processMethodInvocation(MethodInvocation invocation, ModularHypergraph graph, List<String> dataTypePatterns, Node node, TypeDeclaration clazz, MethodDeclaration method) {
    	val typeBinding = invocation.expression.resolveTypeBinding
    	if (typeBinding.isDataType(dataTypePatterns)) {
    		/** This is not a method invocation to be considered in complexity, as it is used with a data type. */
    		return
    	} else {
    		val targetMethodBinding = invocation.resolveMethodBinding
    		val targetNode = graph.findOrCreateTargetNode(typeBinding, targetMethodBinding)
    		
    		val edge = createCallEdge(clazz, method, targetMethodBinding)
	    	graph.edges.add(edge)
	    	node.edges.add(edge)
	    	targetNode.edges.add(edge)
	    	System.out.println("processMethodInvocation " + invocation.name.fullyQualifiedName + " - <" + node.name + "> <" + targetNode.name + "> [" + edge.name + "]")
	    	
	    	/**
	    	 * Parameter node is the correct source node to evaluate the parameters, as all parameters
	    	 * are accessed inside of method and not the instantiated constructor.
	    	 */
	    	invocation.arguments.forEach[argument | (argument as Expression).evaluate(graph, dataTypePatterns, node, clazz, method)]
    	}
    }
    
    /**
     * Recurse over the expression and relate all method invocations to the data property.
     */
	private static def void assignNodesToEdge(Expression expression, ModularHypergraph graph, List<String> dataTypePatterns, Node node, TypeDeclaration clazz, MethodDeclaration method, Edge edge) {
		switch(expression) {
			MethodInvocation: expression.assignNodeToEdge(graph, edge)
			InfixExpression: {
				expression.leftOperand.assignNodesToEdge(graph, dataTypePatterns, node, clazz, method, edge)
				expression.rightOperand?.assignNodesToEdge(graph, dataTypePatterns, node, clazz, method, edge)	
			}
			ClassInstanceCreation: { 
				/** 
				 * data type value initialization => does not cause an edge referencing, 
				 * however check parameter for call edges.
				 */
				expression.arguments.forEach[argument | (argument as Expression).evaluate(graph, dataTypePatterns, node, clazz, method)]
			}
			NumberLiteral, SimpleName, StringLiteral: return
			default:
    			throw new UnsupportedOperationException("Expression type " + expression.class + " is not supported by assignNodesToEdge")
		}
	}
	
    /**
	 * Find or create an node for the given invocation and connect it to the data edge.
	 */
	private static def assignNodeToEdge(MethodInvocation invocation, ModularHypergraph graph, Edge edge) {
		val methodBinding = invocation.resolveMethodBinding
		val node = graph.findOrCreateTargetNode(methodBinding.declaringClass, methodBinding)
		node.edges.add(edge)
		System.out.println("assignNodeToEdge " + invocation.name.fullyQualifiedName + " - <" + node.name + "> [" + edge.name + "]")
		// TODO parameter of the method invocation must be processed for call edges
	}
    
    /**
     * Find the corresponding node in the graph and if none can be found create one.
     * Missing nodes occur, because framework classes are not automatically scanned form method.
     * It a new node is created it is also added to the graph.
     * 
     * @param graph
     * @param typeBinding
     * @param methodBinding
     * 
     * @return returns the found or created node 
     */
    private def static findOrCreateTargetNode(ModularHypergraph graph, ITypeBinding typeBinding, IMethodBinding methodBinding) {
    	var targetNode = graph.nodes.findNodeForMethodBinding(methodBinding)
    	if (targetNode == null) { /** node does not yet exist. It must be a framework class. */
    		var module = graph.modules.findModule(typeBinding)
    		if (module == null) { /** Module does not exists. Add it on demand. */
    			module = createModuleForTypeBinding(typeBinding)
    			graph.modules.add(module) 
    		}
    		targetNode = createNodeForMethod(methodBinding)
    		module.nodes.add(targetNode)
    		graph.nodes.add(targetNode)
    	}
    	
    	return targetNode
    }
    
    /**
     * Determine if a given type is considered a data type.
     */
    private def static boolean isDataType(ITypeBinding type, List<String> dataTypePatterns) {
    	if (type.isPrimitive)
    		return true
    	else
    		return dataTypePatterns.exists[type.determineFullyQualifiedName.matches(it)]
    }
     
    /**
     * Checks if an expression resolves to a class data property.
     * 
     * @param expression the expression to be evaluated
     * 
     * @return true for data properties false otherwise
     */
    private def static boolean isClassDataProperty(Expression expression, List<String> dataTypePatterns, ITypeBinding typeBinding, MethodDeclaration method) {
    	switch(expression) {
    		FieldAccess: {
    			val prefix = expression.expression
    			switch(prefix) {
    				ThisExpression: expression.name.isClassDataProperty(dataTypePatterns, typeBinding, method)
    				default:
    					throw new UnsupportedOperationException("FieldAccess expression type " + expression.class + " is not supported by isClassDataProperty")
    			} 
    		}
    		SimpleName: {
    			val global = typeBinding.declaredFields.findFirst[it.name.equals(expression.fullyQualifiedName) && it.type.isDataType(dataTypePatterns)]
    			return (global != null)
    		}
    		default:
    			throw new UnsupportedOperationException("Expression type " + expression.class + " is not supported by isClassDataProperty")
    	}
    }

    
    /**
     * Find a variable declaration in the local context of a method which conforms to the given name.
     * 
     * @return returns a variable declaration of null
     */
    private def static VariableDeclaration findVariableDeclaration(SimpleName name, Statement statement) {
    	switch(statement) {
    		Block: return findVariableDeclarationInSequence(name, statement.statements)   
    		DoStatement: return findVariableDeclaration(name, statement.body)
    		EnhancedForStatement: {
    			if (statement.parameter.name.fullyQualifiedName.equals(name.fullyQualifiedName))
    				return statement.parameter
    			else
    				return findVariableDeclaration(name, statement.body)
    		}
    		ForStatement: return findVariableDeclaration(name, statement.body)
    		IfStatement: {
    			val then = findVariableDeclaration(name, statement.thenStatement)
    			if (then != null)
    				return then
    			else
    				return findVariableDeclaration(name, statement.elseStatement)
    		}
    		LabeledStatement: return findVariableDeclaration(name, statement.body)
    		SwitchStatement: return findVariableDeclarationInSequence(name, statement.statements)   			
    		SynchronizedStatement: return findVariableDeclaration(name, statement.body)
    		TryStatement: {
    			val declaration = findVariableDeclaration(name, statement.body)
    			if (declaration == null) {
    				for (clause : statement.catchClauses) {
    					val declarationInClause = findVariableDeclaration(name, statement.body)
    					if (declarationInClause != null)
    						return declarationInClause
    				}
    				return findVariableDeclaration(name, statement.^finally)
    			} else
    				return declaration
    		}
    		VariableDeclarationStatement: 
    			return statement.fragments.findFirst[(it as VariableDeclarationFragment).
    				name.fullyQualifiedName.equals(name.fullyQualifiedName)
    			]
    		WhileStatement: return findVariableDeclaration(name, statement.body)
    	}
    }
	
	/**
	 * Handle variable search for statement sequences. 
	 */
	private def static findVariableDeclarationInSequence(SimpleName name, List<Statement> statements) {
		for (statement : statements) {
			val result = findVariableDeclaration(name, statement)
    		if (result != null)
    			return result
    	}
    	return null
	}
	
}