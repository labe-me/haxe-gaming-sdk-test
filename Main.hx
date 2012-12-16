import away3d.core.managers.Stage3DManager;
import away3d.core.managers.Stage3DProxy;
import away3d.events.Stage3DEvent;
import away3d.Away3D;
import away3d.controllers.HoverController;
import away3d.debug.AwayStats;
import away3d.containers.View3D;
import away3d.textures.*;
import away3d.entities.Mesh;
import flash.display.BitmapData;
import starling.core.Starling;

class Main {
    static var stage3DManager : Stage3DManager;
    static var stage3DProxy : Stage3DProxy;
    static var away3dView : View3D;
    static var hoverController : HoverController;
    // Runtime variables
    static var lastPanAngle = 0.0;
    static var lastTiltAngle = 0.0;
    static var lastMouseX = 0.0;
    static var lastMouseY = 0.0;
    static var mouseDown : Bool;
    static var renderOrderDesc : flash.text.TextField;
    static var renderOrder = 0;
    // Constants
    static inline var CHECKERS_CUBES_STARS = 0;
    static inline var STARS_CHECKERS_CUBES = 1;
    static inline var CUBES_STARS_CHECKERS = 2;

    public static function main(){
        flash.Lib.current.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
        flash.Lib.current.stage.align = flash.display.StageAlign.TOP_LEFT;
        stage3DManager = Stage3DManager.getInstance(flash.Lib.current.stage);
        stage3DProxy = stage3DManager.getFreeStage3DProxy();
        stage3DProxy.antiAlias = 8;
        stage3DProxy.color = 0x000000;
        stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_CREATED, function(e){
            initAway3D();
            initStarling();
            initMaterials();
            initObjects();
            initListeners();
        });
    }

    static function initAway3D(){
        away3dView = new View3D();
        away3dView.stage3DProxy = stage3DProxy;
        away3dView.shareContext = true;
        hoverController = new HoverController(away3dView.camera, null, 45, 30, 1200, 5, 89.999);
        flash.Lib.current.addChild(away3dView);
        flash.Lib.current.addChild(new AwayStats(away3dView));
    }

    static var starlingCheckerboard : starling.core.Starling;
    static var starlingStars : starling.core.Starling;
    static var starlingFeathers : starling.core.Starling;

    static function initStarling(){
        starlingCheckerboard = new Starling(StarlingCheckerboardSprite, flash.Lib.current.stage, stage3DProxy.viewPort, stage3DProxy.stage3D);
		// Create the Starling scene to add the particle effect
        starlingStars = new Starling(StarlingStarsSprite, flash.Lib.current.stage, stage3DProxy.viewPort, stage3DProxy.stage3D);
        starlingFeathers = new Starling(FeathersLayer, flash.Lib.current.stage, stage3DProxy.viewPort, stage3DProxy.stage3D);
        starlingFeathers.start();
    }

    static var cubeMaterial : away3d.materials.TextureMaterial;

    static function initMaterials(){
        //Create a material for the cubes
        var cubeBmd = new BitmapData(128, 128, false, 0x0);
        cubeBmd.perlinNoise(7, 7, 5, 12345, true, true, 7, true);
        cubeMaterial = new away3d.materials.TextureMaterial(new BitmapTexture(cubeBmd));
        cubeMaterial.gloss = 20;
        cubeMaterial.ambientColor = 0x808080;
        cubeMaterial.ambient = 1;
    }

    static var cube1 : Mesh;
    static var cube2 : Mesh;
    static var cube3 : Mesh;
    static var cube4 : Mesh;
    static var cube5 : Mesh;

    static function initObjects(){
        // Build the cubes for view 1
        var cG = new away3d.primitives.CubeGeometry(300, 300, 300);
        cube1 = new Mesh(cG, cubeMaterial);
        cube2 = new Mesh(cG, cubeMaterial);
        cube3 = new Mesh(cG, cubeMaterial);
        cube4 = new Mesh(cG, cubeMaterial);
        cube5 = new Mesh(cG, cubeMaterial);

        // Arrange them in a circle with one on the center
        cube1.x = -750;
        cube2.z = -750;
        cube3.x = 750;
        cube4.z = 750;
        cube1.y = cube2.y = cube3.y = cube4.y = cube5.y = 150;

        // Add the cubes to view 1
        away3dView.scene.addChild(cube1);
        away3dView.scene.addChild(cube2);
        away3dView.scene.addChild(cube3);
        away3dView.scene.addChild(cube4);
        away3dView.scene.addChild(cube5);
        //away3dView.scene.addChild(new away3d.primitives.WireframePlane(2500, 2500, 20, 20, 0xbbbb00, 1.5, away3d.primitives.WireframePlane.ORIENTATION_XZ));
    }

    static function initListeners(){
        flash.Lib.current.addEventListener(flash.events.MouseEvent.MOUSE_DOWN, onMouseDown);
		flash.Lib.current.addEventListener(flash.events.MouseEvent.MOUSE_UP, onMouseUp);
        stage3DProxy.addEventListener(flash.events.Event.ENTER_FRAME, onEnterFrame);
    }

    static function onEnterFrame(event : flash.events.Event){
        // Update the hovercontroller for view 1
        if (mouseDown) {
            hoverController.panAngle = 0.3 * (flash.Lib.current.stage.mouseX - lastMouseX) + lastPanAngle;
            hoverController.tiltAngle = 0.3 * (flash.Lib.current.stage.mouseY - lastMouseY) + lastTiltAngle;
        }

        // Update the scenes
        var starlingCheckerboardSprite:StarlingCheckerboardSprite = StarlingCheckerboardSprite.instance;
        if (starlingCheckerboardSprite != null)
            starlingCheckerboardSprite.update();

        // Use the selected rendering order
        if (renderOrder == CHECKERS_CUBES_STARS){
            // Render the Starling animation layer
            starlingCheckerboard.nextFrame();
            // Render the Away3D layer
            away3dView.render();
            // Render the Starling stars layer
            starlingStars.nextFrame();
        }
        else if (renderOrder == STARS_CHECKERS_CUBES){
            // Render the Starling stars layer
            starlingStars.nextFrame();
            // Render the Starling animation layer
            starlingCheckerboard.nextFrame();
            // Render the Away3D layer
            away3dView.render();
        }
        else {
            // Render the Away3D layer
            away3dView.render();
            // Render the Starling stars layer
            starlingStars.nextFrame();
            // Render the Starling animation layer
            starlingCheckerboard.nextFrame();
        }
        starlingFeathers.nextFrame();
    }

    /**
     * Handle the mouse down event and remember details for hovercontroller
     */
    static function onMouseDown(event : flash.events.MouseEvent){
        mouseDown = true;
        lastPanAngle = hoverController.panAngle;
        lastTiltAngle = hoverController.tiltAngle;
        lastMouseX = flash.Lib.current.stage.mouseX;
        lastMouseY = flash.Lib.current.stage.mouseY;
    }

    /**
     * Clear the mouse down flag to stop the hovercontroller
     */
    static function onMouseUp(event : flash.events.MouseEvent){
        mouseDown = false;
    }

    /**
     * Swap the rendering order
     */
    static function onChangeRenderOrder(event : flash.events.MouseEvent){
        nextRenderOrder();
    }

    public static function nextRenderOrder(){
        if (renderOrder == CHECKERS_CUBES_STARS){
            renderOrder = STARS_CHECKERS_CUBES;
        }
        else if (renderOrder == STARS_CHECKERS_CUBES){
            renderOrder = CUBES_STARS_CHECKERS;
        }
        else {
            renderOrder = CHECKERS_CUBES_STARS;
        }
    }
}

import flash.display.GradientType;

class StarlingCheckerboardSprite extends starling.display.Sprite {
    public static var instance : StarlingCheckerboardSprite;

    var container : starling.display.Sprite;

    public function new(){
        super();
        instance = this;
        var m = new flash.geom.Matrix();
        m.createGradientBox(512, 512, 0, 0, 0);

        // Create gradient background
        var fS = new flash.display.Sprite();
        fS.graphics.beginGradientFill(GradientType.RADIAL, [ 0xaa0000, 0x0088aa ], [ 1, 1 ], [ 0, 255 ], m);
        fS.graphics.drawRect(0, 0, 512, 512);
        fS.graphics.endFill();

        // Draw the gradient to the bitmap data
        var checkers = new flash.display.BitmapData(512, 512, true, 0x0);
        checkers.draw(fS);

        // Create the holes in the board (bitmap data)
        for (yP in 0...16){
            for (xP in 0...16){
                if ((yP + xP) % 2 == 0) {
                    checkers.fillRect(new flash.geom.Rectangle(xP * 32, yP * 32, 32, 32), 0x0);
                }
            }
        }

        // Create the Starling texture from the bitmapdata
        var checkerTx = starling.textures.Texture.fromBitmapData(checkers);

        // Create a sprite and add an image using the checker texture
        // Assign the pivot point in the centre of the sprite
        container = new starling.display.Sprite();
        container.pivotX = container.pivotY = 256;
        container.x = 400;
        container.y = 300;
        container.scaleX = container.scaleY = 2;

        container.addChild(new starling.display.Image(checkerTx));
        // Add the container sprite to the Starling stage
        addChild(container);
    }

    public function update(){
        container.rotation += 0.005;
    }
}

@:bitmap("pdesign.png") class StarsParticle extends flash.display.BitmapData {}
@:file("pdesign.pex") class StarsConfig extends flash.utils.ByteArray {}

class StarlingStarsSprite extends starling.display.Sprite {
    static var instance : StarlingStarsSprite;

    private var mParticleSystem:starling.extensions.ParticleSystem;

    public function new(){
        super();
        instance = this;
        var psConfig = new flash.xml.XML(new StarsConfig().toString());
        var psTexture = starling.textures.Texture.fromBitmapData(new StarsParticle(0,0));

        mParticleSystem = new starling.extensions.PDParticleSystem(psConfig, psTexture);
        mParticleSystem.emitterX = flash.Lib.current.stage.stageWidth/2;
        mParticleSystem.emitterY = flash.Lib.current.stage.stageHeight;
        this.addChild(mParticleSystem);

        Starling.juggler.add(mParticleSystem);

        mParticleSystem.start();
    }
}

class FeathersLayer extends starling.display.Sprite {
    public static var instance : FeathersLayer;
    var theme : MyTheme;
    public function new(){
        super();
        instance = this;
        theme = new MyTheme(this, false);
        var button = new feathers.controls.Button();
        button.label = "Feather button, change display order";
        button.addEventListener(starling.events.Event.TRIGGERED, function(e){
            Main.nextRenderOrder();
        });
        this.addChild( button );
    }
}

class MyTheme extends feathers.themes.AzureMobileTheme {
    public function new(root, scaleToDPI=true){
        super(root, scaleToDPI);
    }
}