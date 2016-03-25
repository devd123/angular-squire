import angular  from 'angular';
import Squire   from 'squire-rte';
import template from './template';

const module = angular.module('angular-squire', []);

// TEMPLATES & SELECTORS ///////////////////////////////////////////////////////

const iframeTemplate = `
    <iframe
        border="0"
        frameborder="0"
        marginheight="0"
        marginwidth="0"
        src="about:blank">
    </iframe>
`;

const stylesheetSelector =
    `link[rel="stylesheet"]`;

// PROVIDER ////////////////////////////////////////////////////////////////////

class SquireService {
    constructor(opts) {
        this.opts = opts;
    }

    createSquireElement(scope, elem) {
        const iframe = angular.element(iframeTemplate)[0];

        return new Promise(resolve => {
            iframe.addEventListener('load', () => {

                const frameDoc = iframe.contentWindow.document;
                const links    = document.querySelectorAll(stylesheetSelector);
                const classes  = [ this.opts.defaultIframeClass, scope.editorClass ]
                    .filter(n => n).join(' ');

                Array.from(links).map(link => link.outerHTML).forEach(html =>
                    frameDoc.head.insertAdjacentHTML('beforeend', html)
                );

                frameDoc.body.className = classes;

                const editor = new Squire(frameDoc);

                editor.defaultBlockTag = 'P';

                resolve({ editor, iframe });
            });
        });
    }
}

class SquireServiceProvider {
    constructor() {
        this.defaultLinkText = 'http://';

        this.defaultIframeClass = 'angular-squire-iframe';

        this.defaultButtons = {
            bold:      true,
            italic:    true,
            link:      true,
            ol:        true,
            ul:        true,
            underline: true
        };
    }

    $get() {
        return new SquireService(this);
    }
}

module.provider('squireService', SquireServiceProvider);

// PRIME DIRECTIVE /////////////////////////////////////////////////////////////

module.directive('squire', squireService => ({
    restrict: 'E',
    require: 'ngModel',
    template,
    scope: {
        editorClass: '@'
        placeholder: '@'
    },
    link: async (scope, elem, attr, modelCtrl) => {
        const menubar = elem[0].querySelector('.menu');

        // Edit button settings

        scope.buttons = { ...squireService.opts.defaultButtons };

        scope.$watchCollection(() => Object.assign(
                scope.buttonObject,
                scope.$eval(attr.buttons || '{}')
            ), () => {}
        );

        scope.data = { link: squireService.opts.defaultLinkText };

        // NgModel configuration

        modelCtrl.$isEmpty = value => {
            const vessel = document.createElement('div');

            vessel.innerHTML = value || '';

            return !vessel.textContent.trim().length;
        };

        modelCtrl.$render = () =>
            scope.editor && scope.editor.setHTML(modelCtrl.$viewValue || '');

        // Squire element hookup

        const { editor } = await squireService.createSquireElement(scope, elem);

        editor.setHTML(modelCtrl.$viewValue || '');

        editor.addEventListener('blur', event => {
            elem.removeClass('focus');
            elem.triggerHandler('blur');
            modelCtrl.$setTouched();

            // Original cod had this, and it seems like a mistake to me:
            //
            // if ngModel.$pristine and not ngModel.$isEmpty(ngModel.$viewValue)
            //     ngModel.$setTouched()
            // else
            //     ngModel.$setPristine()
            //
            // Whatever represents a blur should always $setTouched; that’s the
            // premise of ‘$touchedness.’ There’s also no occasion I can think
            // of (?) when it’s a good idea to call $setPristine from within an
            // input directive. ‘Resetting’ comes from above, not within.
        });

        editor.addEventListener('focus', event => {
            elem.addClass('focus');
            elem.triggerHandler('focus');
        });

        editor.addEventListener('input', event => {
            const html = editor.getHTML();
            updateModel(html);
        });

        editor.addEventListener('pathChange', event => {
            const path = editor.getPath();

            const addLinks = elem[0].querySelectorAll('.add-link');

            if (addLinks.length) {
                const isAnchor = />A\b/.test(path) || editor.hasFormat('A');

                const action =  isAnchor ? 'add' : 'remove';

                Array.from(addLinks).forEach(
                    link => link.classList[action]('active')
                );

                const [ , value ] = path.split('BODY')

                const classNames = value
                    .replace(/>|\.|html|body|div/ig, ' ')
                    .toLowerCase();

                menubar.setAttribute('class', `menu ${ classNames }`);
            }



            // menubar.attr("class", "menu " +
            //     p.split("BODY")[1].replace(/>|\.|html|body|div/ig, ' ')
            //     .replace(RegExp(HEADER_CLASS, 'g'), 'size')
            //     .toLowerCase())
        });

    },
    controller: $scope => {

    }
}));

module.directive('squireCover', () => ({}));

module.directive('squireControls', () => ({}));
