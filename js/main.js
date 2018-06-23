"use strict";

(function(){

	function loadData(path, success, error)
	{
    	var xhr = new XMLHttpRequest();
    	xhr.onreadystatechange = function()
    	{
	        if (xhr.readyState === XMLHttpRequest.DONE) {
	            if (xhr.status === 200) {
	                if (success)
	                    success(xhr.responseText);
	            } else {
	                if (error)
	                    error(xhr);
	            }
        }
    }
    	xhr.open("GET", path, true);
    	xhr.send();
	}

	function onErr(error){
		console.error("Error loading shader ", error);
	}

	function loadShaders(vertexPath, fragmentPath, error){
		var vertexShader;
		var fragmentShader;

		var onVertexLoadSuccess = function(result){
			vertexShader = result;
			loadData(fragmentPath, onFragmentLoadSuccess, error);
		}

		var onFragmentLoadSuccess = function(result){
			fragmentShader = result;
			init(vertexShader, fragmentShader);
		}

		loadData(vertexPath, onVertexLoadSuccess, error);
	}

	function init(vertexShader, fragmentShader){
		var scene = new Scene({
			vertexShader : vertexShader,
			fragmentShader : fragmentShader,
			canvas : document.getElementById("raymarchCanvas")
		});

		scene.render(0);
	}


    var SHAPE = {
    	PLANE : {
    		//to tell how to draw lines between vertices
    		indices : [0, 1, 0, 2, 0, 1, 0, 2, 0, 1, 0, 3],
    		vertices : [-1, -1, 0, 1, -1, 0, -1, 1, 0, -1, 1, 0, 1, -1, 0, 1, 1, 0],
    		uvs : [0, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1]
    	},
    	SPHERE : {
    		vertices : [-1, -1, 0, 1, -1, 0, -1, 1, 0, -1, 1, 0, 1, -1, 0, 1, 1, 0],
    		uvs : [0, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1]
    	}
    };

    //returns vertices and uvs for easier shape creation
    function createShape(shape){
    	return {
	  		position: {
	  			numComponents :	3, 
	  			data : shape.vertices
	  		},
	  		uv : {
				numComponents : 2,
				data : shape.uv
			}
	  	};
    }


    //todo refactor using just Webgl?
	function Scene(options){

		this.vertexShader = options.vertexShader;
		this.fragmentShader = options.fragmentShader;
		this.canvas = options.canvas;
		this.context = this.canvas.getContext("webgl")
		//loads the shaders
		this.programInfo = twgl.createProgramInfo(this.context, [this.vertexShader, this.fragmentShader]);
		
		//create plane
		var shapeInfo = createShape(SHAPE.PLANE);
		// var shapeInfo = twgl.primitives.createPlaneVertices(1);
	  	//create buffer object that is used for attributes like position and uvs
	  	this.bufferInfo = twgl.createBufferInfoFromArrays(this.context, shapeInfo);

		this.render = function(time) {
			console.log(this.bufferInfo);
			debugger
	    	twgl.resizeCanvasToDisplaySize(this.canvas);
		    this.context.viewport(0, 0, this.canvas.width, this.canvas.height);

		    var projectionMatrix = twgl.m4.identity();
		    var uniforms = {
		    	//projectionMatrix : projectionMatrix,
		      	time: time * 0.001,
		      	resolution: [this.canvas.width, this.canvas.height],
		    };

		    this.context.useProgram(this.programInfo.program);
		    twgl.setBuffersAndAttributes(this.context, this.programInfo, this.bufferInfo);
		    twgl.setUniforms(this.programInfo, uniforms);
		    twgl.drawBufferInfo(this.context, this.bufferInfo);

		    requestAnimationFrame(render);
		}

	}

	loadShaders("js/shaders/vertex.glsl", "js/shaders/fragment.glsl", onErr);


})();