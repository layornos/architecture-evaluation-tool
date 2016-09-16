package de.cau.cs.se.software.evaluation.jobs

import org.eclipse.core.resources.IFile
import org.eclipse.core.resources.IProject
import org.eclipse.swt.widgets.Shell

interface IAnalysisJobProvider {
	/**
	 * Returns the file extension the job is designed for.
	 */
	def String getFileExtension()

	def AbstractHypergraphAnalysisJob createAnalysisJob(IProject project, IFile file, Shell shell)
}