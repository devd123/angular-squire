# angular-squire
angularjs directive for the [squire rich text editor](https://github.com/neilj/Squire). 

Check out the [DEMO](http://hourlynerd.github.io/angular-squire/)

# install

```bash
bower install angular-squire --save
```

or include the following in your code:

```bash
/dist/css/angular-squire.css
/dist/scripts/angular-squire.js
```

# usage

add an angular module dependency: `angular-squire`

basic usage of the directive looks like this:  
```html
<squire editor-class="foo" height="150px"
    ng-model="myModel" body="initialValue"
    placeholder="Type in here!">
</squire>
```

*Attributes:*  
`editor-class` - class given to the editor container (optional)  
`height` - css height for the editor (optional)  
`width` - css width for the editor (optional)
`body` - binding that contains the initial html contents of the editor, if different from `ng-model` (optional)
`ng-model` - where does the html go? **required**  
`placeholder` - placeholder text (optional) 


## With cover and controls
You can use `<squire-cover>` and `<squire-controls>` elements within the body of the `<squire>` tag.

squire-cover will display its contents instead of the editor until you click on it, at which point it will hide
and show you the editor and the controls (optional)


squire-controls will place it's contents within the squire div. Its purpose is to add buttons under the editor which
 you can hide and show together with the editor.

 Example:
 ```html
 <squire height="150px" ng-model="bar" name="body" placeholder="why do you like cats?" required>
     <squire-cover>
         <div style="border: 1px solid #dde6e8; color: #bbb; padding: 10px; cursor: pointer;">Click if you like cats</div>
     </squire-cover>
     <squire-controls>
         <div class="form-group">
             <button class="btn btn-primary pull-right" style="margin-top: 10px;" type="button">Meow</button>
         </div>
     </squire-controls>
 </squire>
```

# changing the template

If you want to change the editor's template html, you can do so by putting your custom template into
the `$templateCache` under the key `/modules/angular-squire/editor.html` *after* you include this
directive's javascript.

For example html template see [current template](https://raw.githubusercontent.com/HourlyNerd/angular-squire/master/app/modules/angular-squire/editor.html)


For advanced usage see [demo](http://hourlynerd.github.io/angular-squire/).

# customizing scss styles

The dist dir comes with the original sass stylesheet used to generate the css.
You may elect to include this instead of the css if you already use sass in your project.

The scss file `dist/css/angular_squire.scss` contains some variables which you may override:

```scss
$angular-squire-border-radius: 5px !default;
$angular-squire-container-bg: #dde6e8 !default;
$angular-squire-border-color: #dde6e8 !default;
$angular-squire-popover-bg: #FAFAFA !default;
$angular-squire-highlight-color: #55ACEE !default;
$angular-squire-wrapper-padding: 5px 0 !default;
```

# depends on

```js
"angular": "~1.3.8",
"underscore": "~1.7.0",
"jquery": ">= 1.9.0",
"font-awesome": "~4.3.0",
"squire-rte": "~1.0.1"
```

# building

```bash
npm install bower -g
npm install gulp -g
npm install
bower install
gulp build
```
