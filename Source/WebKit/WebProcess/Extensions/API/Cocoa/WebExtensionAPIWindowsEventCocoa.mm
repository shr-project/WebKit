/*
 * Copyright (C) 2023 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#if !__has_feature(objc_arc)
#error This file requires ARC. Add the "-fobjc-arc" compiler flag for this file.
#endif

#import "config.h"
#import "WebExtensionAPIWindowsEvent.h"

#import "CocoaHelpers.h"
#import "MessageSenderInlines.h"
#import "WebExtensionAPIWindows.h"
#import "WebExtensionContextMessages.h"
#import "WebPageProxy.h"
#import "WebProcess.h"
#import "_WKWebExtensionUtilities.h"

#if ENABLE(WK_WEB_EXTENSIONS)

namespace WebKit {

void WebExtensionAPIWindowsEvent::invokeListenersWithArgument(id argument, WindowTypeFilter windowType)
{
    if (m_listeners.isEmpty())
        return;

    for (auto& listener : m_listeners) {
        if (!listener.second.contains(windowType))
            continue;

        listener.first->call(argument);
    }
}

void WebExtensionAPIWindowsEvent::addListener(WebPage* page, RefPtr<WebExtensionCallbackHandler> listener, NSDictionary *filter, NSString **outExceptionString)
{
    OptionSet<WindowTypeFilter> windowTypeFilter;
    if (!WebExtensionAPIWindows::parseWindowTypesFilter(filter, windowTypeFilter, outExceptionString))
        return;

    m_listeners.append({ listener, windowTypeFilter });

    if (!page)
        return;

    WebProcess::singleton().send(Messages::WebExtensionContext::AddListener(page->webPageProxyIdentifier(), m_type), extensionContext().identifier());
}

void WebExtensionAPIWindowsEvent::removeListener(WebPage* page, RefPtr<WebExtensionCallbackHandler> listener)
{
    m_listeners.removeAllMatching([&](auto& entry) {
        return entry.first->callbackFunction() == listener->callbackFunction();
    });

    if (!page)
        return;

    WebProcess::singleton().send(Messages::WebExtensionContext::RemoveListener(page->webPageProxyIdentifier(), m_type), extensionContext().identifier());
}

bool WebExtensionAPIWindowsEvent::hasListener(RefPtr<WebExtensionCallbackHandler> listener)
{
    return m_listeners.containsIf([&](auto& entry) {
        return entry.first->callbackFunction() == listener->callbackFunction();
    });
}

} // namespace WebKit

#endif // ENABLE(WK_WEB_EXTENSIONS)
