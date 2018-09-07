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

	//use arrow funcs?
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
    		vertices : [-1, -1, 0, 1, -1, 0, -1, 1, 0, -1, 1, 0, 1, -1, 0, 1, 1, 0]
    	},
    	SQUARE : {
    		//to tell how to draw lines between vertices
    		vertices : [1.0, 1.0, -1.0, 1.0, 1.0, -1.0, -1.0, -1.0]
    	}
    };

    var glHelper = {
    	createProgram : function(){

    	},
    	createPositionBuffer : function(){

    	},
    	compileShader : function(glContext, shaderText, shaderType){
			var shader = glContext.createShader(shaderType);
	  		glContext.shaderSource(shader, shaderText);
	  		glContext.compileShader(shader);

			if (!glContext.getShaderParameter(shader, glContext.COMPILE_STATUS)) {
    			console.error('An error occurred compiling the shaders: ' + glContext.getShaderInfoLog(shader));
    			glContext.deleteShader(shader);
    			return null;
  			}

	  		return shader;
    	}
    };


	function Scene(options){
		this.canvas = options.canvas;
		var gl = this.canvas.getContext("webgl");

	  	var vertShader = glHelper.compileShader(gl, options.vertexShader, gl.VERTEX_SHADER);
	  	var fragShader = glHelper.compileShader(gl, options.fragmentShader, gl.FRAGMENT_SHADER);
	 
	  	//create the program to use the shaders
	  	var program = gl.createProgram();
	  	gl.attachShader(program, vertShader);
	  	gl.attachShader(program, fragShader);
	  	gl.linkProgram(program);
	  	gl.useProgram(program);

	  	gl.clearColor(0, 0, 0, 1);
		gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

		var programInfo = {
		    program: program,
		    attribLocations: {
		      position: gl.getAttribLocation(program, 'position')
		     // uv: gl.getAttribLocation(program, 'uv')
		    },
		    uniformLocations: {
		      time: gl.getUniformLocation(program, 'iTime'),
		      resolution: gl.getUniformLocation(program, 'iResolution'),
		      mouse: gl.getUniformLocation(program, 'iMouse')
		    }
 		};

		//create buffer for square
		var positionBuffer = gl.createBuffer();
		//now we need to bind the buffer to the operations of position buffer
		gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
  		//now populate the buffer with positions, positionBuffer will be populated now,
  		//and set to static draw for more efficiency
  		gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(SHAPE.SQUARE.vertices), gl.STATIC_DRAW);

		gl.enable(gl.DEPTH_TEST);          
  		gl.depthFunc(gl.LEQUAL); 
  		
  		var self = this;

  		// todo change this
  		var focused = true;
  		document.addEventListener("focus", function(){
  			focused = true;
  		});
  		document.addEventListener("blur", function(){
  			focused = false;
  		});

		this.render = function(time) {
			gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
			gl.useProgram(programInfo.program);

			//use position buffer
			gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
			//find position attribute in shader
			gl.vertexAttribPointer(
				programInfo.attribLocations.position,
				2,
				gl.FLOAT,
				false,
				0,
				0
			);

			gl.enableVertexAttribArray(programInfo.attribLocations.position);
			gl.useProgram(programInfo.program);

			//set uniforms
			gl.uniform1f(programInfo.uniformLocations.time, time/1000.);
			gl.uniform2fv(programInfo.uniformLocations.resolution, [self.canvas.width, self.canvas.height]);
			gl.uniform4fv(programInfo.uniformLocations.mouse, [0, 0, 0, 0]);

			//quite cool, dont need to set all the vertices!!
			var offset = 0;
    		var vertexCount = 4;
			gl.drawArrays(gl.TRIANGLE_STRIP, offset, vertexCount);

			if(focused){
		    	// requestAnimationFrame(self.render);
			}
		}
	}

	loadShaders("js/shaders/vertex.glsl", "js/shaders/fragment.glsl", onErr);

})();