package de.cau.cs.se.evaluation.architecture.transformation;

import com.google.common.base.Objects;
import java.util.List;
import org.eclipse.jdt.core.dom.ASTNode;
import org.eclipse.jdt.core.dom.AbstractTypeDeclaration;
import org.eclipse.jdt.core.dom.ArrayType;
import org.eclipse.jdt.core.dom.CompilationUnit;
import org.eclipse.jdt.core.dom.ConstructorInvocation;
import org.eclipse.jdt.core.dom.IMethodBinding;
import org.eclipse.jdt.core.dom.IPackageBinding;
import org.eclipse.jdt.core.dom.ITypeBinding;
import org.eclipse.jdt.core.dom.MethodDeclaration;
import org.eclipse.jdt.core.dom.MethodInvocation;
import org.eclipse.jdt.core.dom.Name;
import org.eclipse.jdt.core.dom.PackageDeclaration;
import org.eclipse.jdt.core.dom.ParameterizedType;
import org.eclipse.jdt.core.dom.PrimitiveType;
import org.eclipse.jdt.core.dom.QualifiedType;
import org.eclipse.jdt.core.dom.SimpleName;
import org.eclipse.jdt.core.dom.SimpleType;
import org.eclipse.jdt.core.dom.SingleVariableDeclaration;
import org.eclipse.jdt.core.dom.SuperConstructorInvocation;
import org.eclipse.jdt.core.dom.Type;
import org.eclipse.jdt.core.dom.UnionType;
import org.eclipse.jdt.core.dom.VariableDeclarationFragment;
import org.eclipse.jdt.core.dom.WildcardType;
import org.eclipse.xtext.xbase.lib.Conversions;
import org.eclipse.xtext.xbase.lib.Functions.Function1;
import org.eclipse.xtext.xbase.lib.IterableExtensions;
import org.eclipse.xtext.xbase.lib.ListExtensions;

@SuppressWarnings("all")
public class NameResolutionHelper {
  /**
   * Fully qualified name of a property of a class
   */
  public static String determineFullyQualifiedName(final AbstractTypeDeclaration clazz, final VariableDeclarationFragment fragment) {
    String _determineFullyQualifiedName = NameResolutionHelper.determineFullyQualifiedName(clazz);
    String _plus = (_determineFullyQualifiedName + ".");
    SimpleName _name = fragment.getName();
    String _fullyQualifiedName = _name.getFullyQualifiedName();
    return (_plus + _fullyQualifiedName);
  }
  
  /**
   * Fully qualified name of a class specified by a class declaration
   */
  private static String determineFullyQualifiedName(final AbstractTypeDeclaration clazz) {
    ASTNode _parent = clazz.getParent();
    PackageDeclaration _package = ((CompilationUnit) _parent).getPackage();
    Name _name = _package.getName();
    String _fullyQualifiedName = _name.getFullyQualifiedName();
    String _plus = (_fullyQualifiedName + ".");
    SimpleName _name_1 = clazz.getName();
    String _fullyQualifiedName_1 = _name_1.getFullyQualifiedName();
    final String name = (_plus + _fullyQualifiedName_1);
    return name;
  }
  
  /**
   * Fully qualified name of a class specified by a type binding
   */
  public static String determineFullyQualifiedName(final ITypeBinding clazz) {
    IPackageBinding _package = clazz.getPackage();
    String _name = _package.getName();
    String _plus = (_name + ".");
    String _name_1 = clazz.getName();
    final String name = (_plus + _name_1);
    return name;
  }
  
  /**
   * Fully qualified name of a method based on the method binding.
   */
  public static String determineFullyQualifiedName(final IMethodBinding binding) {
    ITypeBinding _declaringClass = binding.getDeclaringClass();
    String _determineFullyQualifiedName = NameResolutionHelper.determineFullyQualifiedName(_declaringClass);
    String _plus = (_determineFullyQualifiedName + ".");
    String _name = binding.getName();
    final String name = (_plus + _name);
    return name;
  }
  
  /**
   * Determine the name of a calling method.
   */
  public static String determineFullyQualifiedName(final AbstractTypeDeclaration clazz, final MethodDeclaration method) {
    String _determineFullyQualifiedName = NameResolutionHelper.determineFullyQualifiedName(clazz);
    String _plus = (_determineFullyQualifiedName + ".");
    SimpleName _name = method.getName();
    String _fullyQualifiedName = _name.getFullyQualifiedName();
    String _plus_1 = (_plus + _fullyQualifiedName);
    String _plus_2 = (_plus_1 + "(");
    List _parameters = method.parameters();
    final Function1<Object, String> _function = new Function1<Object, String>() {
      public String apply(final Object it) {
        Type _type = ((SingleVariableDeclaration) it).getType();
        return NameResolutionHelper.determineFullyQualifiedName(_type);
      }
    };
    List<String> _map = ListExtensions.<Object, String>map(_parameters, _function);
    String _join = IterableExtensions.join(_map, ",");
    String _plus_3 = (_plus_2 + _join);
    String _plus_4 = (_plus_3 + ") : ");
    Type _returnType2 = method.getReturnType2();
    String _determineFullyQualifiedName_1 = NameResolutionHelper.determineFullyQualifiedName(_returnType2);
    final String result = (_plus_4 + _determineFullyQualifiedName_1);
    List _thrownExceptionTypes = method.thrownExceptionTypes();
    int _size = _thrownExceptionTypes.size();
    boolean _greaterThan = (_size > 0);
    if (_greaterThan) {
      List _thrownExceptionTypes_1 = method.thrownExceptionTypes();
      final Function1<Object, String> _function_1 = new Function1<Object, String>() {
        public String apply(final Object it) {
          return NameResolutionHelper.determineFullyQualifiedName(((Type) it));
        }
      };
      List<String> _map_1 = ListExtensions.<Object, String>map(_thrownExceptionTypes_1, _function_1);
      String _join_1 = IterableExtensions.join(_map_1, ",");
      return ((result + " throw ") + _join_1);
    } else {
      return result;
    }
  }
  
  /**
   * Determine the name of a called method.
   */
  public static String determineFullyQualifiedName(final AbstractTypeDeclaration clazz, final MethodInvocation callee) {
    String _determineFullyQualifiedName = NameResolutionHelper.determineFullyQualifiedName(clazz);
    String _plus = (_determineFullyQualifiedName + ".");
    SimpleName _name = callee.getName();
    String _fullyQualifiedName = _name.getFullyQualifiedName();
    String _plus_1 = (_plus + _fullyQualifiedName);
    String _plus_2 = (_plus_1 + "(");
    IMethodBinding _resolveMethodBinding = callee.resolveMethodBinding();
    ITypeBinding[] _parameterTypes = _resolveMethodBinding.getParameterTypes();
    final Function1<ITypeBinding, String> _function = new Function1<ITypeBinding, String>() {
      public String apply(final ITypeBinding it) {
        return it.getQualifiedName();
      }
    };
    List<String> _map = ListExtensions.<ITypeBinding, String>map(((List<ITypeBinding>)Conversions.doWrapArray(_parameterTypes)), _function);
    String _join = IterableExtensions.join(_map, ",");
    String _plus_3 = (_plus_2 + _join);
    String _plus_4 = (_plus_3 + ") : ");
    IMethodBinding _resolveMethodBinding_1 = callee.resolveMethodBinding();
    ITypeBinding _returnType = _resolveMethodBinding_1.getReturnType();
    String _qualifiedName = _returnType.getQualifiedName();
    final String result = (_plus_4 + _qualifiedName);
    IMethodBinding _resolveMethodBinding_2 = callee.resolveMethodBinding();
    ITypeBinding[] _exceptionTypes = _resolveMethodBinding_2.getExceptionTypes();
    int _length = _exceptionTypes.length;
    boolean _greaterThan = (_length > 0);
    if (_greaterThan) {
      IMethodBinding _resolveMethodBinding_3 = callee.resolveMethodBinding();
      ITypeBinding[] _exceptionTypes_1 = _resolveMethodBinding_3.getExceptionTypes();
      final Function1<ITypeBinding, String> _function_1 = new Function1<ITypeBinding, String>() {
        public String apply(final ITypeBinding it) {
          return it.getQualifiedName();
        }
      };
      List<String> _map_1 = ListExtensions.<ITypeBinding, String>map(((List<ITypeBinding>)Conversions.doWrapArray(_exceptionTypes_1)), _function_1);
      String _join_1 = IterableExtensions.join(_map_1, ",");
      return ((result + " throw ") + _join_1);
    } else {
      return result;
    }
  }
  
  /**
   * Determine the name of a called constructor.
   */
  public static String determineFullyQualifiedName(final AbstractTypeDeclaration clazz, final ConstructorInvocation callee) {
    String _determineFullyQualifiedName = NameResolutionHelper.determineFullyQualifiedName(clazz);
    String _plus = (_determineFullyQualifiedName + ".");
    SimpleName _name = clazz.getName();
    String _fullyQualifiedName = _name.getFullyQualifiedName();
    String _plus_1 = (_plus + _fullyQualifiedName);
    String _plus_2 = (_plus_1 + "(");
    IMethodBinding _resolveConstructorBinding = callee.resolveConstructorBinding();
    ITypeBinding[] _parameterTypes = _resolveConstructorBinding.getParameterTypes();
    final Function1<ITypeBinding, String> _function = new Function1<ITypeBinding, String>() {
      public String apply(final ITypeBinding it) {
        return it.getQualifiedName();
      }
    };
    List<String> _map = ListExtensions.<ITypeBinding, String>map(((List<ITypeBinding>)Conversions.doWrapArray(_parameterTypes)), _function);
    String _join = IterableExtensions.join(_map, ",");
    String _plus_3 = (_plus_2 + _join);
    final String result = (_plus_3 + ") ");
    IMethodBinding _resolveConstructorBinding_1 = callee.resolveConstructorBinding();
    ITypeBinding[] _exceptionTypes = _resolveConstructorBinding_1.getExceptionTypes();
    int _length = _exceptionTypes.length;
    boolean _greaterThan = (_length > 0);
    if (_greaterThan) {
      IMethodBinding _resolveConstructorBinding_2 = callee.resolveConstructorBinding();
      ITypeBinding[] _exceptionTypes_1 = _resolveConstructorBinding_2.getExceptionTypes();
      final Function1<ITypeBinding, String> _function_1 = new Function1<ITypeBinding, String>() {
        public String apply(final ITypeBinding it) {
          return it.getQualifiedName();
        }
      };
      List<String> _map_1 = ListExtensions.<ITypeBinding, String>map(((List<ITypeBinding>)Conversions.doWrapArray(_exceptionTypes_1)), _function_1);
      String _join_1 = IterableExtensions.join(_map_1, ",");
      return ((result + " throw ") + _join_1);
    } else {
      return result;
    }
  }
  
  /**
   * Determine the name of a called constructor.
   */
  public static String determineFullyQualifiedName(final AbstractTypeDeclaration clazz, final SuperConstructorInvocation callee) {
    String _determineFullyQualifiedName = NameResolutionHelper.determineFullyQualifiedName(clazz);
    String _plus = (_determineFullyQualifiedName + ".");
    SimpleName _name = clazz.getName();
    String _fullyQualifiedName = _name.getFullyQualifiedName();
    String _plus_1 = (_plus + _fullyQualifiedName);
    String _plus_2 = (_plus_1 + "(");
    IMethodBinding _resolveConstructorBinding = callee.resolveConstructorBinding();
    ITypeBinding[] _parameterTypes = _resolveConstructorBinding.getParameterTypes();
    final Function1<ITypeBinding, String> _function = new Function1<ITypeBinding, String>() {
      public String apply(final ITypeBinding it) {
        return it.getQualifiedName();
      }
    };
    List<String> _map = ListExtensions.<ITypeBinding, String>map(((List<ITypeBinding>)Conversions.doWrapArray(_parameterTypes)), _function);
    String _join = IterableExtensions.join(_map, ",");
    String _plus_3 = (_plus_2 + _join);
    final String result = (_plus_3 + ") ");
    IMethodBinding _resolveConstructorBinding_1 = callee.resolveConstructorBinding();
    ITypeBinding[] _exceptionTypes = _resolveConstructorBinding_1.getExceptionTypes();
    int _length = _exceptionTypes.length;
    boolean _greaterThan = (_length > 0);
    if (_greaterThan) {
      IMethodBinding _resolveConstructorBinding_2 = callee.resolveConstructorBinding();
      ITypeBinding[] _exceptionTypes_1 = _resolveConstructorBinding_2.getExceptionTypes();
      final Function1<ITypeBinding, String> _function_1 = new Function1<ITypeBinding, String>() {
        public String apply(final ITypeBinding it) {
          return it.getQualifiedName();
        }
      };
      List<String> _map_1 = ListExtensions.<ITypeBinding, String>map(((List<ITypeBinding>)Conversions.doWrapArray(_exceptionTypes_1)), _function_1);
      String _join_1 = IterableExtensions.join(_map_1, ",");
      return ((result + " throw ") + _join_1);
    } else {
      return result;
    }
  }
  
  /**
   * Fully qualified name of a type.
   */
  public static String determineFullyQualifiedName(final Type type) {
    boolean _matched = false;
    if (!_matched) {
      if (type instanceof ArrayType) {
        _matched=true;
        Type _elementType = ((ArrayType)type).getElementType();
        String _determineFullyQualifiedName = NameResolutionHelper.determineFullyQualifiedName(_elementType);
        return (_determineFullyQualifiedName + "[]");
      }
    }
    if (!_matched) {
      if (type instanceof ParameterizedType) {
        _matched=true;
        Type _type = ((ParameterizedType)type).getType();
        String _determineFullyQualifiedName = NameResolutionHelper.determineFullyQualifiedName(_type);
        String _plus = (_determineFullyQualifiedName + "<");
        List _typeArguments = ((ParameterizedType)type).typeArguments();
        final Function1<Object, String> _function = new Function1<Object, String>() {
          public String apply(final Object it) {
            return NameResolutionHelper.determineFullyQualifiedName(((Type) it));
          }
        };
        List<String> _map = ListExtensions.<Object, String>map(_typeArguments, _function);
        String _join = IterableExtensions.join(_map, ",");
        String _plus_1 = (_plus + _join);
        return (_plus_1 + ">");
      }
    }
    if (!_matched) {
      if (type instanceof PrimitiveType) {
        _matched=true;
        String _switchResult_1 = null;
        PrimitiveType.Code _primitiveTypeCode = ((PrimitiveType)type).getPrimitiveTypeCode();
        boolean _matched_1 = false;
        if (!_matched_1) {
          if (Objects.equal(_primitiveTypeCode, PrimitiveType.BOOLEAN)) {
            _matched_1=true;
            _switchResult_1 = "boolean";
          }
        }
        if (!_matched_1) {
          if (Objects.equal(_primitiveTypeCode, PrimitiveType.BYTE)) {
            _matched_1=true;
            _switchResult_1 = "byte";
          }
        }
        if (!_matched_1) {
          if (Objects.equal(_primitiveTypeCode, PrimitiveType.CHAR)) {
            _matched_1=true;
            _switchResult_1 = "char";
          }
        }
        if (!_matched_1) {
          if (Objects.equal(_primitiveTypeCode, PrimitiveType.DOUBLE)) {
            _matched_1=true;
            _switchResult_1 = "double";
          }
        }
        if (!_matched_1) {
          if (Objects.equal(_primitiveTypeCode, PrimitiveType.FLOAT)) {
            _matched_1=true;
            _switchResult_1 = "float";
          }
        }
        if (!_matched_1) {
          if (Objects.equal(_primitiveTypeCode, PrimitiveType.INT)) {
            _matched_1=true;
            _switchResult_1 = "int";
          }
        }
        if (!_matched_1) {
          if (Objects.equal(_primitiveTypeCode, PrimitiveType.LONG)) {
            _matched_1=true;
            _switchResult_1 = "long";
          }
        }
        if (!_matched_1) {
          if (Objects.equal(_primitiveTypeCode, PrimitiveType.SHORT)) {
            _matched_1=true;
            _switchResult_1 = "short";
          }
        }
        if (!_matched_1) {
          if (Objects.equal(_primitiveTypeCode, PrimitiveType.VOID)) {
            _matched_1=true;
            _switchResult_1 = "void";
          }
        }
        return _switchResult_1;
      }
    }
    if (!_matched) {
      if (type instanceof QualifiedType) {
        _matched=true;
        String _xifexpression = null;
        boolean _and = false;
        SimpleName _name = ((QualifiedType)type).getName();
        boolean _notEquals = (!Objects.equal(_name, null));
        if (!_notEquals) {
          _and = false;
        } else {
          Type _qualifier = ((QualifiedType)type).getQualifier();
          boolean _notEquals_1 = (!Objects.equal(_qualifier, null));
          _and = _notEquals_1;
        }
        if (_and) {
          SimpleName _name_1 = ((QualifiedType)type).getName();
          String _fullyQualifiedName = _name_1.getFullyQualifiedName();
          String _plus = (_fullyQualifiedName + ".");
          Type _qualifier_1 = ((QualifiedType)type).getQualifier();
          String _determineFullyQualifiedName = NameResolutionHelper.determineFullyQualifiedName(_qualifier_1);
          _xifexpression = (_plus + _determineFullyQualifiedName);
        } else {
          String _xifexpression_1 = null;
          SimpleName _name_2 = ((QualifiedType)type).getName();
          boolean _notEquals_2 = (!Objects.equal(_name_2, null));
          if (_notEquals_2) {
            SimpleName _name_3 = ((QualifiedType)type).getName();
            _xifexpression_1 = _name_3.getFullyQualifiedName();
          } else {
            Type _qualifier_2 = ((QualifiedType)type).getQualifier();
            _xifexpression_1 = NameResolutionHelper.determineFullyQualifiedName(_qualifier_2);
          }
          _xifexpression = _xifexpression_1;
        }
        return _xifexpression;
      }
    }
    if (!_matched) {
      if (type instanceof SimpleType) {
        _matched=true;
        Name _name = ((SimpleType)type).getName();
        return _name.getFullyQualifiedName();
      }
    }
    if (!_matched) {
      if (type instanceof UnionType) {
        _matched=true;
        List _types = ((UnionType)type).types();
        final Function1<Object, String> _function = new Function1<Object, String>() {
          public String apply(final Object it) {
            return NameResolutionHelper.determineFullyQualifiedName(((Type) it));
          }
        };
        List<String> _map = ListExtensions.<Object, String>map(_types, _function);
        return IterableExtensions.join(_map, "+");
      }
    }
    if (!_matched) {
      if (type instanceof WildcardType) {
        _matched=true;
        boolean _isUpperBound = ((WildcardType)type).isUpperBound();
        if (_isUpperBound) {
          Type _bound = ((WildcardType)type).getBound();
          String _determineFullyQualifiedName = NameResolutionHelper.determineFullyQualifiedName(_bound);
          return ("? extends " + _determineFullyQualifiedName);
        } else {
          Type _bound_1 = ((WildcardType)type).getBound();
          String _determineFullyQualifiedName_1 = NameResolutionHelper.determineFullyQualifiedName(_bound_1);
          return ("? super " + _determineFullyQualifiedName_1);
        }
      }
    }
    return "ERROR";
  }
}